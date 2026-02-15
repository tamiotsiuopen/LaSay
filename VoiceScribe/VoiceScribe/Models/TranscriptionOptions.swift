//
//  TranscriptionOptions.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

enum TranscriptionMode: String, CaseIterable {
    case cloud
    case local

    var localizedDisplayName: String {
        let language = LocalizationHelper.shared.currentLanguage
        switch self {
        case .cloud:
            return language == "zh" ? "雲端（OpenAI）" : "Cloud (OpenAI)"
        case .local:
            return language == "zh" ? "本地（離線可用）" : "Local (Offline)"
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
        let language = LocalizationHelper.shared.currentLanguage
        switch self {
        case .auto:
            return language == "zh" ? "自動偵測" : "Auto Detect"
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

enum PunctuationStyle: String, CaseIterable {
    case fullWidth
    case halfWidth
    case spaces
    
    var localizedDisplayName: String {
        let language = LocalizationHelper.shared.currentLanguage
        switch self {
        case .fullWidth:
            return language == "zh" ? "全形" : "Full-width"
        case .halfWidth:
            return language == "zh" ? "半形" : "Half-width"
        case .spaces:
            return language == "zh" ? "空格" : "Spaces"
        }
    }
}
