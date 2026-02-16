//
//  SenseVoiceCppWrapper.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation
import AVFoundation

final class SenseVoiceCppWrapper {
    private var recognizer: OpaquePointer? // SherpaOnnxOfflineRecognizer

    init?(modelDir: String) {
        let modelPath = (modelDir as NSString).appendingPathComponent("model.int8.onnx")
        let tokensPath = (modelDir as NSString).appendingPathComponent("tokens.txt")

        guard FileManager.default.fileExists(atPath: modelPath),
              FileManager.default.fileExists(atPath: tokensPath) else {
            return nil
        }

        var senseVoiceConfig = SherpaOnnxOfflineSenseVoiceModelConfig()
        // Zero out
        memset(&senseVoiceConfig, 0, MemoryLayout<SherpaOnnxOfflineSenseVoiceModelConfig>.size)

        let modelCStr = strdup(modelPath)
        let languageCStr = strdup("auto")
        defer {
            free(modelCStr)
            free(languageCStr)
        }
        senseVoiceConfig.model = UnsafePointer(modelCStr)
        senseVoiceConfig.language = UnsafePointer(languageCStr)
        senseVoiceConfig.use_itn = 1

        var modelConfig = SherpaOnnxOfflineModelConfig()
        memset(&modelConfig, 0, MemoryLayout<SherpaOnnxOfflineModelConfig>.size)

        let tokensCStr = strdup(tokensPath)
        let providerCStr = strdup("cpu")
        defer {
            free(tokensCStr)
            free(providerCStr)
        }
        modelConfig.tokens = UnsafePointer(tokensCStr)
        modelConfig.num_threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 1))
        modelConfig.provider = UnsafePointer(providerCStr)
        modelConfig.debug = 0
        modelConfig.sense_voice = senseVoiceConfig

        var recognizerConfig = SherpaOnnxOfflineRecognizerConfig()
        memset(&recognizerConfig, 0, MemoryLayout<SherpaOnnxOfflineRecognizerConfig>.size)

        let decodingCStr = strdup("greedy_search")
        defer { free(decodingCStr) }
        recognizerConfig.decoding_method = UnsafePointer(decodingCStr)
        recognizerConfig.model_config = modelConfig

        recognizer = SherpaOnnxCreateOfflineRecognizer(&recognizerConfig)
        if recognizer == nil { return nil }
    }

    deinit {
        if let recognizer = recognizer {
            SherpaOnnxDestroyOfflineRecognizer(recognizer)
        }
    }

    /// Transcribe a 16kHz mono WAV file. Returns the transcribed text.
    func transcribe(wavURL: URL, language: String?) -> String? {
        guard let recognizer = recognizer else { return nil }

        // Use sherpa-onnx's built-in WAV reader
        let wavPath = wavURL.path
        guard let wave = SherpaOnnxReadWave(wavPath) else { return nil }
        defer { SherpaOnnxFreeWave(wave) }

        guard let stream = SherpaOnnxCreateOfflineStream(recognizer) else { return nil }
        defer { SherpaOnnxDestroyOfflineStream(stream) }

        SherpaOnnxAcceptWaveformOffline(stream, wave.pointee.sample_rate, wave.pointee.samples, wave.pointee.num_samples)
        SherpaOnnxDecodeOfflineStream(recognizer, stream)

        guard let result = SherpaOnnxGetOfflineStreamResult(stream) else { return nil }
        defer { SherpaOnnxDestroyOfflineRecognizerResult(result) }

        guard let textPtr = result.pointee.text else { return nil }
        let text = String(cString: textPtr).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
