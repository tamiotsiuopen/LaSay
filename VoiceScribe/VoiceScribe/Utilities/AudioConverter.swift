//
//  AudioConverter.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation
import AVFoundation

/// Sandbox-safe audio converter using AVFoundation (no Process/shell).
enum AudioConverter {
    /// Convert any supported audio file to 16kHz mono 16-bit PCM WAV.
    /// Returns the URL of the converted file, or nil on failure.
    static func convertToWAV(inputURL: URL) -> URL? {
        let wavURL = inputURL.deletingPathExtension().appendingPathExtension("wav")

        // Remove existing output
        try? FileManager.default.removeItem(at: wavURL)

        guard let inputFile = try? AVAudioFile(forReading: inputURL) else { return nil }

        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )!

        guard let converter = AVAudioConverter(from: inputFile.processingFormat, to: outputFormat) else { return nil }

        // Calculate output frame count
        let ratio = 16000.0 / inputFile.processingFormat.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(inputFile.length) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else { return nil }

        // Read all input into a buffer
        let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFile.processingFormat,
            frameCapacity: AVAudioFrameCount(inputFile.length)
        )!

        do {
            try inputFile.read(into: inputBuffer)
        } catch {
            return nil
        }

        // Convert
        var error: NSError?
        var inputConsumed = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if let error = error {
            // AudioConverter error: \(error)
            return nil
        }

        // Write output WAV
        guard let outputFile = try? AVAudioFile(
            forWriting: wavURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        ) else { return nil }

        do {
            try outputFile.write(from: outputBuffer)
        } catch {
            return nil
        }

        return wavURL
    }
}
