//
//  LocalWhisperService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

final class LocalWhisperService {
    static let shared = LocalWhisperService()

    struct DownloadProgress {
        let kind: DownloadKind
        let fraction: Double
        let bytesReceived: Int64
        let bytesExpected: Int64
        let isCompleted: Bool
    }

    enum DownloadKind {
        case model
    }

    typealias DownloadProgressHandler = (DownloadProgress) -> Void

    private let fileManager = FileManager.default
    private var progressObservations: [Int: NSKeyValueObservation] = [:]
    private let modelFileName = "ggml-large-v3-turbo.bin"
    private let modelDownloadURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin")!

    private var whisperWrapper: WhisperCppWrapper?

    private init() {}

    var isModelDownloaded: Bool {
        fileManager.fileExists(atPath: modelFileURL.path)
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

        ensureModel(progressHandler: progressHandler) { [weak self] modelResult in
            switch modelResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let modelURL):
                self?.runTranscription(modelURL: modelURL, audioFileURL: audioFileURL, language: language, completion: completion)
            }
        }
    }

    // MARK: - Paths

    private var baseDirectory: URL {
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return supportDir.appendingPathComponent("LaSay", isDirectory: true)
    }

    private var modelsDirectory: URL {
        baseDirectory.appendingPathComponent("models", isDirectory: true)
    }

    private var modelFileURL: URL {
        modelsDirectory.appendingPathComponent(modelFileName)
    }

    // MARK: - Model Download

    private func ensureModel(
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, WhisperError>) -> Void
    ) {
        if fileManager.fileExists(atPath: modelFileURL.path) {
            completion(.success(modelFileURL))
            return
        }

        do {
            try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

        downloadFile(
            from: modelDownloadURL,
            to: modelFileURL,
            label: "Model",
            kind: .model,
            progressHandler: progressHandler
        ) { result in
            switch result {
            case .success:
                completion(.success(self.modelFileURL))
            case .failure:
                completion(.failure(.modelDownloadFailed))
            }
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
            if process.terminationStatus == 0 {
                return wavURL
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    private func runTranscription(
        modelURL: URL,
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
            if self.whisperWrapper == nil {
                self.whisperWrapper = WhisperCppWrapper(modelPath: modelURL.path)
            }

            guard let wrapper = self.whisperWrapper else {
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
        label: String,
        kind: DownloadKind,
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let request = URLRequest(url: url)
        var taskId: Int?
        let task = URLSession.shared.downloadTask(with: request) { [weak self] tempURL, response, error in
            defer {
                if let taskId = taskId {
                    self?.progressObservations.removeValue(forKey: taskId)
                }
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "LocalWhisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
                return
            }

            let bytesExpected = response?.expectedContentLength ?? -1

            do {
                if self?.fileManager.fileExists(atPath: destination.path) == true {
                    try self?.fileManager.removeItem(at: destination)
                }
                try self?.fileManager.moveItem(at: tempURL, to: destination)

                let attrs = try? self?.fileManager.attributesOfItem(atPath: destination.path)
                let fileSize = (attrs?[.size] as? Int64) ?? bytesExpected

                DispatchQueue.main.async {
                    progressHandler?(DownloadProgress(
                        kind: kind,
                        fraction: 1.0,
                        bytesReceived: fileSize,
                        bytesExpected: fileSize,
                        isCompleted: true
                    ))
                }
                completion(.success(destination))
            } catch {
                completion(.failure(error))
            }
        }

        taskId = task.taskIdentifier

        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                progressHandler?(DownloadProgress(
                    kind: kind,
                    fraction: progress.fractionCompleted,
                    bytesReceived: progress.completedUnitCount,
                    bytesExpected: progress.totalUnitCount,
                    isCompleted: false
                ))
            }
        }

        if let taskId = taskId {
            progressObservations[taskId] = observation
        }
        task.resume()
    }
}
