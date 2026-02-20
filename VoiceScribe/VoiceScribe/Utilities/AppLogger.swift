//
//  AppLogger.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/20.
//

import os.log

/// Centralised logging wrapper for LaSay.
/// Usage:
///   AppLogger.recording.info("Recording started")
///   AppLogger.api.error("API call failed: \(error.localizedDescription, privacy: .public)")
final class AppLogger {

    private static let subsystem = "com.tamio.LaSay"

    static let recording     = Logger(subsystem: subsystem, category: "recording")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let api           = Logger(subsystem: subsystem, category: "api")
    static let ui            = Logger(subsystem: subsystem, category: "ui")
    static let general       = Logger(subsystem: subsystem, category: "general")
}
