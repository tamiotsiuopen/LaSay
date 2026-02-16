//
//  TranscriptionOptions.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

enum TranscriptionMode: String, CaseIterable {
    case cloud
    case senseVoice

    var localizedDisplayName: String {
        switch self {
        case .cloud: return "雲端（OpenAI）"
        case .senseVoice: return "SenseVoice（離線可用）推薦"
        }
    }

    /// Load from UserDefaults with backward compatibility
    static func fromSaved(_ rawValue: String?) -> TranscriptionMode {
        guard let raw = rawValue else { return .senseVoice }
        if raw == "local" || raw == "whisperLocal" { return .senseVoice }
        return TranscriptionMode(rawValue: raw) ?? .senseVoice
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
        case .auto: return "自動偵測"
        case .zh: return "繁體中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    var languageCode: String? {
        switch self {
        case .auto: return nil
        default: return rawValue
        }
    }
}

enum PunctuationStyle: String, CaseIterable {
    case fullWidth
    case halfWidth
    case spaces
    
    var localizedDisplayName: String {
        switch self {
        case .fullWidth: return "全形"
        case .halfWidth: return "半形"
        case .spaces: return "空格"
        }
    }
}
