//
//  WhisperCppWrapper.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation
import AVFoundation

final class WhisperCppWrapper {
    private var ctx: OpaquePointer?

    init?(modelPath: String) {
        let cparams = whisper_context_default_params()
        ctx = whisper_init_from_file_with_params(modelPath, cparams)
        if ctx == nil { return nil }
    }

    deinit {
        if let ctx = ctx {
            whisper_free(ctx)
        }
    }

    /// Transcribe a 16kHz mono WAV file. Returns the transcribed text.
    func transcribe(wavURL: URL, language: String?) -> String? {
        guard let samples = loadWAVSamples(url: wavURL) else { return nil }
        guard let ctx = ctx else { return nil }

        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

        let lang = language ?? "auto"
        let result: Int32 = lang.withCString { langPtr in
            params.language = langPtr
            params.detect_language = (language == nil)
            params.print_progress = false
            params.print_special = false
            params.print_realtime = false
            params.print_timestamps = false
            params.n_threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 1))

            return samples.withUnsafeBufferPointer { buf in
                whisper_full(ctx, params, buf.baseAddress, Int32(buf.count))
            }
        }

        guard result == 0 else { return nil }

        let nSegments = whisper_full_n_segments(ctx)
        var text = ""
        for i in 0..<nSegments {
            if let cStr = whisper_full_get_segment_text(ctx, i) {
                text += String(cString: cStr)
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Read a 16-bit PCM WAV file and return Float32 samples normalized to [-1, 1].
    private func loadWAVSamples(url: URL) -> [Float]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        // WAV header is 44 bytes for standard PCM
        guard data.count > 44 else { return nil }

        let pcmData = data.advanced(by: 44)
        let sampleCount = pcmData.count / 2 // 16-bit = 2 bytes per sample
        var samples = [Float](repeating: 0, count: sampleCount)

        pcmData.withUnsafeBytes { raw in
            let int16Ptr = raw.bindMemory(to: Int16.self)
            for i in 0..<sampleCount {
                samples[i] = Float(int16Ptr[i]) / 32768.0
            }
        }

        return samples
    }
}
