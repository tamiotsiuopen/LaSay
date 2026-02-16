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

    // Model files downloaded individually (sandbox-safe, no tar/Process needed)
    private let modelOnnxURL = URL(string: "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx")!
    private let tokensURL = URL(string: "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt")!

    private var wrapper: SenseVoiceCppWrapper?
    private(set) var isModelLoaded: Bool = false
    private var isLoadingModel: Bool = false

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

    /// Pre-load model into memory (call when user switches to SenseVoice mode).
    /// Completion is called on main thread.
    func preloadModel(progressHandler: DownloadProgressHandler? = nil, completion: ((Bool) -> Void)? = nil) {
        guard !isModelLoaded, !isLoadingModel else {
            completion?(isModelLoaded)
            return
        }
        isLoadingModel = true
        ensureModel(progressHandler: progressHandler) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let modelDir):
                DispatchQueue.global(qos: .userInitiated).async {
                    if self.wrapper == nil {
                        self.wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
                    }
                    let loaded = self.wrapper != nil
                    DispatchQueue.main.async {
                        self.isModelLoaded = loaded
                        self.isLoadingModel = false
                        completion?(loaded)
                    }
                }
            case .failure:
                DispatchQueue.main.async {
                    self.isLoadingModel = false
                    completion?(false)
                }
            }
        }
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

        // Download model.int8.onnx first (large file, ~228MB), then tokens.txt
        downloadFile(from: modelOnnxURL, to: modelOnnxPath, progressHandler: progressHandler) { [weak self] onnxResult in
            guard let self = self else { return }
            switch onnxResult {
            case .failure:
                completion(.failure(.modelDownloadFailed))
            case .success:
                // Download tokens.txt (small file)
                self.downloadFile(from: self.tokensURL, to: self.tokensPath, progressHandler: nil) { tokensResult in
                    switch tokensResult {
                    case .failure:
                        // Clean up partial download
                        try? self.fileManager.removeItem(at: self.modelOnnxPath)
                        completion(.failure(.modelDownloadFailed))
                    case .success:
                        DispatchQueue.main.async {
                            progressHandler?(DownloadProgress(fraction: 1.0, bytesReceived: 0, bytesExpected: 0, isCompleted: true))
                            completion(.success(self.senseVoiceModelDir.path))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Transcription

    private func convertToWAV(inputURL: URL) -> URL? {
        AudioConverter.convertToWAV(inputURL: inputURL)
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
