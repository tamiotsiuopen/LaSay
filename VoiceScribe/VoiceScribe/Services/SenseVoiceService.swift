//
//  SenseVoiceService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation
import os.log

final class SenseVoiceService {
    static let shared = SenseVoiceService()

    private let fileManager = FileManager.default
    private let modelQueue = DispatchQueue(label: "com.lasay.sensevoice.model")
    private var wrapper: SenseVoiceCppWrapper?
    private(set) var isModelLoaded: Bool = false
    private var isLoadingModel: Bool = false

    private init() {}

    // MARK: - Paths

    /// Model files are bundled in app Resources/
    /// Xcode copies them directly to Resources root (no subfolder).
    private var bundledModelDir: String? {
        Bundle.main.resourcePath
    }

    // MARK: - Public

    /// Pre-load model into memory (call on app launch).
    func preloadModel(completion: ((Bool) -> Void)? = nil) {
        guard !isModelLoaded, !isLoadingModel else {
            completion?(isModelLoaded)
            return
        }
        guard let modelDir = bundledModelDir else {
            AppLogger.transcription.error("SenseVoiceService: bundled model directory not found")
            completion?(false)
            return
        }

        AppLogger.transcription.info("SenseVoiceService: starting model preload")
        isLoadingModel = true
        modelQueue.async { [weak self] in
            guard let self = self else { return }
            if self.wrapper == nil {
                self.wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
            }
            let loaded = self.wrapper != nil
            DispatchQueue.main.async {
                if loaded {
                    AppLogger.transcription.info("SenseVoiceService: model loaded successfully")
                } else {
                    AppLogger.transcription.error("SenseVoiceService: model load failed")
                }
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
            AppLogger.transcription.error("SenseVoiceService: bundled model directory not found")
            completion(.failure(.modelDownloadFailed))
            return
        }

        // If wrapper is nil (model not yet loaded), attempt one reload before transcribing
        if wrapper == nil {
            AppLogger.transcription.info("SenseVoiceService: wrapper nil at transcribe call, attempting reload before transcription")
            modelQueue.async { [weak self] in
                guard let self = self else { return }
                if self.wrapper == nil {
                    self.wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
                    if self.wrapper != nil {
                        AppLogger.transcription.info("SenseVoiceService: reload succeeded")
                        DispatchQueue.main.async { self.isModelLoaded = true }
                    } else {
                        AppLogger.transcription.error("SenseVoiceService: reload failed, returning modelDownloadFailed")
                        DispatchQueue.main.async { completion(.failure(.modelDownloadFailed)) }
                        return
                    }
                }
                self.runTranscription(modelDir: modelDir, audioFileURL: audioFileURL, language: language, completion: completion)
            }
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
        AppLogger.transcription.info("SenseVoiceService: starting transcription")
        modelQueue.async { [weak self] in
            guard let self = self else { return }

            // Convert to WAV if needed
            let wavURL: URL
            if audioFileURL.pathExtension.lowercased() != "wav" {
                guard let converted = AudioConverter.convertToWAV(inputURL: audioFileURL) else {
                    AppLogger.transcription.error("SenseVoiceService: audio conversion to WAV failed")
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
                AppLogger.transcription.info("SenseVoiceService: model not loaded, attempting to load now")
                self.wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
                if self.wrapper != nil {
                    AppLogger.transcription.info("SenseVoiceService: model loaded successfully on demand")
                } else {
                    AppLogger.transcription.error("SenseVoiceService: on-demand model load failed")
                }
            }

            guard let wrapper = self.wrapper else {
                DispatchQueue.main.async { completion(.failure(.modelDownloadFailed)) }
                return
            }

            guard let text = wrapper.transcribe(wavURL: wavURL, language: language) else {
                AppLogger.transcription.error("SenseVoiceService: transcription returned nil result")
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            AppLogger.transcription.info("SenseVoiceService: transcription succeeded, length=\(text.count, privacy: .public) chars")
            DispatchQueue.main.async {
                self.isModelLoaded = true
                completion(.success(text))
            }
        }
    }
}
