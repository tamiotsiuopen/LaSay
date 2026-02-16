//
//  SenseVoiceService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation

final class SenseVoiceService {
    static let shared = SenseVoiceService()

    private let fileManager = FileManager.default
    private var wrapper: SenseVoiceCppWrapper?
    private(set) var isModelLoaded: Bool = false
    private var isLoadingModel: Bool = false

    private init() {}

    // MARK: - Paths

    /// Model files are bundled in app Resources/SenseVoiceModel/
    private var bundledModelDir: String? {
        Bundle.main.resourcePath.map { ($0 as NSString).appendingPathComponent("SenseVoiceModel") }
    }

    // MARK: - Public

    /// Pre-load model into memory (call on app launch).
    func preloadModel(completion: ((Bool) -> Void)? = nil) {
        guard !isModelLoaded, !isLoadingModel else {
            completion?(isModelLoaded)
            return
        }
        guard let modelDir = bundledModelDir else {
            completion?(false)
            return
        }

        isLoadingModel = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
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
    }

    func transcribe(
        audioFileURL: URL,
        language: String? = nil,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        guard fileManager.fileExists(atPath: audioFileURL.path) else {
            completion(.failure(.invalidAudioFile))
            return
        }

        guard let modelDir = bundledModelDir else {
            completion(.failure(.modelDownloadFailed))
            return
        }

        runTranscription(modelDir: modelDir, audioFileURL: audioFileURL, language: language, completion: completion)
    }

    // MARK: - Transcription

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
                guard let converted = AudioConverter.convertToWAV(inputURL: audioFileURL) else {
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

            DispatchQueue.main.async {
                self.isModelLoaded = true
                completion(.success(text))
            }
        }
    }
}
