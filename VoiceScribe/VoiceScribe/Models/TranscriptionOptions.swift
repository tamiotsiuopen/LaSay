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

enum PolishTemplate: String, CaseIterable {
    case general
    case meeting
    case email
    case social
    case todo

    var displayName: String {
        switch self {
        case .general:
            return "General Conversation"
        case .meeting:
            return "Meeting Notes"
        case .email:
            return "Email"
        case .social:
            return "Social Post"
        case .todo:
            return "TODO List"
        }
    }
}
