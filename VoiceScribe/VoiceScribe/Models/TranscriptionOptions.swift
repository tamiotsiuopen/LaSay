//
//  TranscriptionOptions.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import Foundation

enum TranscriptionMode: String, CaseIterable {
    case cloud
    case local

    var displayName: String {
        switch self {
        case .cloud:
            return "Cloud (OpenAI)"
        case .local:
            return "Local (Whisper.cpp)"
        }
    }

    var localizedDisplayName: String {
        let language = LocalizationHelper.shared.currentLanguage
        switch self {
        case .cloud:
            return language == "zh" ? "雲端（OpenAI）" : "Cloud (OpenAI)"
        case .local:
            return language == "zh" ? "本地（Whisper.cpp）" : "Local (Whisper.cpp)"
        }
    }
}

enum TranscriptionLanguage: String, CaseIterable {
    case auto
    case zh
    case en
    case ja
    case ko

    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .zh:
            return "繁體中文"
        case .en:
            return "English"
        case .ja:
            return "日本語"
        case .ko:
            return "한국어"
        }
    }

    var whisperCode: String? {
        switch self {
        case .auto:
            return nil
        default:
            return rawValue
        }
    }
}
