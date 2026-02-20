//
//  AppSettings.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/20.
//

import Foundation

final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    private init() {}

    var transcriptionMode: TranscriptionMode {
        get { TranscriptionMode.fromSaved(defaults.string(forKey: "transcription_mode")) }
        set { defaults.set(newValue.rawValue, forKey: "transcription_mode") }
    }

    var transcriptionLanguage: TranscriptionLanguage {
        get {
            guard let raw = defaults.string(forKey: "transcription_language"),
                  let lang = TranscriptionLanguage(rawValue: raw) else { return .auto }
            return lang
        }
        set { defaults.set(newValue.rawValue, forKey: "transcription_language") }
    }

    var punctuationStyle: PunctuationStyle {
        get {
            guard let raw = defaults.string(forKey: "punctuation_style"),
                  let style = PunctuationStyle(rawValue: raw) else { return .fullWidth }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: "punctuation_style") }
    }

    var enableAIPolish: Bool {
        get { defaults.bool(forKey: "enable_ai_polish") }
        set { defaults.set(newValue, forKey: "enable_ai_polish") }
    }

    var customSystemPrompt: String? {
        get { defaults.string(forKey: "custom_system_prompt") }
        set { defaults.set(newValue, forKey: "custom_system_prompt") }
    }

    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: "has_launched_before") }
        set { defaults.set(newValue, forKey: "has_launched_before") }
    }
}
