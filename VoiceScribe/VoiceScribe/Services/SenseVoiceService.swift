//
//  SenseVoiceService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation

final class SenseVoiceService {
    static let shared = SenseVoiceService()

    struct DownloadProgress {
        let fraction: Double
        let bytesReceived: Int64
        let bytesExpected: Int64
        let isCompleted: Bool
    }

    typealias DownloadProgressHandler = (DownloadProgress) -> Void

    private let fileManager = FileManager.default
    private var progressObservation: NSKeyValueObservation?

    // Model is ~228MB int8 + tokens
    private let modelArchiveURL = URL(string: "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17.tar.bz2")!
    private let modelDirName = "sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17"

    private var wrapper: SenseVoiceCppWrapper?

    private init() {}

    // MARK: - Paths

    private var baseDirectory: URL {
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return supportDir.appendingPathComponent("LaSay", isDirectory: true)
    }

    private var modelsDirectory: URL {
        baseDirectory.appendingPathComponent("models", isDirectory: true)
    }

    private var senseVoiceModelDir: URL {
        modelsDirectory.appendingPathComponent("sensevoice", isDirectory: true)
    }

    private var modelOnnxPath: URL {
        senseVoiceModelDir.appendingPathComponent("model.int8.onnx")
    }

    private var tokensPath: URL {
        senseVoiceModelDir.appendingPathComponent("tokens.txt")
    }

    // MARK: - Public

    var isModelDownloaded: Bool {
        fileManager.fileExists(atPath: modelOnnxPath.path) &&
        fileManager.fileExists(atPath: tokensPath.path)
    }

    func predownload() {
        ensureModel(progressHandler: nil) { _ in }
    }

    func transcribe(
        audioFileURL: URL,
        language: String? = nil,
        progressHandler: DownloadProgressHandler? = nil,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        guard fileManager.fileExists(atPath: audioFileURL.path) else {
            completion(.failure(.invalidAudioFile))
            return
        }

        ensureModel(progressHandler: progressHandler) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let modelDir):
                self?.runTranscription(modelDir: modelDir, audioFileURL: audioFileURL, language: language, completion: completion)
            }
        }
    }

    // MARK: - Model Download

    private func ensureModel(
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        if isModelDownloaded {
            completion(.success(senseVoiceModelDir.path))
            return
        }

        do {
            try fileManager.createDirectory(at: senseVoiceModelDir, withIntermediateDirectories: true)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

        // Download tar.bz2, extract model.int8.onnx and tokens.txt
        let tempArchive = modelsDirectory.appendingPathComponent("sensevoice-temp.tar.bz2")
        downloadFile(from: modelArchiveURL, to: tempArchive, progressHandler: progressHandler) { [weak self] dlResult in
            guard let self = self else { return }
            switch dlResult {
            case .failure:
                completion(.failure(.modelDownloadFailed))
            case .success:
                // Extract needed files using tar
                DispatchQueue.global(qos: .userInitiated).async {
                    let success = self.extractModelFiles(archive: tempArchive)
                    try? self.fileManager.removeItem(at: tempArchive)

                    DispatchQueue.main.async {
                        if success && self.isModelDownloaded {
                            progressHandler?(DownloadProgress(fraction: 1.0, bytesReceived: 0, bytesExpected: 0, isCompleted: true))
                            completion(.success(self.senseVoiceModelDir.path))
                        } else {
                            completion(.failure(.modelDownloadFailed))
                        }
                    }
                }
            }
        }
    }

    private func extractModelFiles(archive: URL) -> Bool {
        // Extract model.int8.onnx and tokens.txt from the tar.bz2
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = [
            "xjf", archive.path,
            "-C", senseVoiceModelDir.path,
            "--strip-components=1",
            "\(modelDirName)/model.int8.onnx",
            "\(modelDirName)/tokens.txt"
        ]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Transcription

    private func convertToWAV(inputURL: URL) -> URL? {
        let wavURL = inputURL.deletingPathExtension().appendingPathExtension("wav")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
        process.arguments = [
            inputURL.path,
            wavURL.path,
            "-d", "LEI16",
            "-f", "WAVE",
            "-r", "16000",
            "-c", "1"
        ]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0 ? wavURL : nil
        } catch {
            return nil
        }
    }

    private func runTranscription(
        modelDir: String,
        audioFileURL: URL,
        language: String?,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Convert to WAV if needed
            let wavURL: URL
            if audioFileURL.pathExtension.lowercased() != "wav" {
                guard let converted = self.convertToWAV(inputURL: audioFileURL) else {
                    DispatchQueue.main.async { completion(.failure(.invalidAudioFile)) }
                    return
                }
                wavURL = converted
            } else {
                wavURL = audioFileURL
            }
            defer {
                if wavURL != audioFileURL {
                    try? FileManager.default.removeItem(at: wavURL)
                }
            }

            // Load model if needed
            if self.wrapper == nil {
                self.wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
            }

            guard let wrapper = self.wrapper else {
                DispatchQueue.main.async { completion(.failure(.modelDownloadFailed)) }
                return
            }

            guard let text = wrapper.transcribe(wavURL: wavURL, language: language) else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            DispatchQueue.main.async { completion(.success(text)) }
        }
    }

    // MARK: - Download Helper

    private func downloadFile(
        from url: URL,
        to destination: URL,
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            self?.progressObservation = nil

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "SenseVoice", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
                return
            }

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
                completion(.success(destination))
            } catch {
                completion(.failure(error))
            }
        }

        progressObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                progressHandler?(DownloadProgress(
                    fraction: progress.fractionCompleted,
                    bytesReceived: progress.completedUnitCount,
                    bytesExpected: progress.totalUnitCount,
                    isCompleted: false
                ))
            }
        }

        task.resume()
    }
}
