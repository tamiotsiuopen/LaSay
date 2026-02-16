//
//  SenseVoiceCppWrapper.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation

final class SenseVoiceCppWrapper {
    private var recognizer: OpaquePointer? // SherpaOnnxOfflineRecognizer

    init?(modelDir: String) {
        let modelPath = (modelDir as NSString).appendingPathComponent("model.int8.onnx")
        let tokensPath = (modelDir as NSString).appendingPathComponent("tokens.txt")

        guard FileManager.default.fileExists(atPath: modelPath),
              FileManager.default.fileExists(atPath: tokensPath) else {
            return nil
        }

        // Use withCString to safely pass C strings without strdup/free lifecycle issues
        let result: OpaquePointer? = modelPath.withCString { modelCStr in
            "auto".withCString { languageCStr in
                tokensPath.withCString { tokensCStr in
                    "cpu".withCString { providerCStr in
                        "greedy_search".withCString { decodingCStr in
                            var senseVoiceConfig = SherpaOnnxOfflineSenseVoiceModelConfig()
                            memset(&senseVoiceConfig, 0, MemoryLayout<SherpaOnnxOfflineSenseVoiceModelConfig>.size)
                            senseVoiceConfig.model = modelCStr
                            senseVoiceConfig.language = languageCStr
                            senseVoiceConfig.use_itn = 1

                            var modelConfig = SherpaOnnxOfflineModelConfig()
                            memset(&modelConfig, 0, MemoryLayout<SherpaOnnxOfflineModelConfig>.size)
                            modelConfig.tokens = tokensCStr
                            modelConfig.num_threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 1))
                            modelConfig.provider = providerCStr
                            modelConfig.debug = 0
                            modelConfig.sense_voice = senseVoiceConfig

                            var recognizerConfig = SherpaOnnxOfflineRecognizerConfig()
                            memset(&recognizerConfig, 0, MemoryLayout<SherpaOnnxOfflineRecognizerConfig>.size)
                            recognizerConfig.decoding_method = decodingCStr
                            recognizerConfig.model_config = modelConfig

                            return SherpaOnnxCreateOfflineRecognizer(&recognizerConfig)
                        }
                    }
                }
            }
        }

        recognizer = result
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
