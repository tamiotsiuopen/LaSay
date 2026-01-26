//
//  LocalizationHelper.swift
//  LaSay
//
//  Created by Claude on 2026/1/26.
//

import Foundation

class LocalizationHelper {
    static let shared = LocalizationHelper()

    private init() {}

    var currentLanguage: String {
        UserDefaults.standard.string(forKey: "ui_language") ?? "zh"
    }

    func localized(_ key: LocalizationKey) -> String {
        let language = currentLanguage

        switch key {
        // 設定視窗
        case .settings:
            return language == "zh" ? "設定" : "Settings"
        case .openAIAPIKey:
            return language == "zh" ? "OpenAI API Key" : "OpenAI API Key"
        case .apiKeySet:
            return language == "zh" ? "✅ 已設定 API Key" : "✅ API Key Set"
        case .show:
            return language == "zh" ? "顯示" : "Show"
        case .hide:
            return language == "zh" ? "隱藏" : "Hide"
        case .update:
            return language == "zh" ? "更新" : "Update"
        case .cancel:
            return language == "zh" ? "取消" : "Cancel"
        case .enterAPIKey:
            return language == "zh" ? "請輸入 API Key (sk-...)" : "Enter API Key (sk-...)"
        case .apiKeyDescription:
            return language == "zh" ? "用於 Whisper 語音轉錄與 AI 文字潤飾" : "Used for Whisper transcription and AI text polishing"

        // 介面語言
        case .uiLanguage:
            return language == "zh" ? "介面語言" : "Interface Language"
        case .language:
            return language == "zh" ? "語言" : "Language"
        case .autoDetectLanguage:
            return language == "zh" ? "語音轉錄會自動辨識所有語言" : "Speech transcription automatically detects all languages"

        // 快捷鍵
        case .globalHotkey:
            return language == "zh" ? "全域快捷鍵" : "Global Hotkey"
        case .currentHotkey:
            return language == "zh" ? "當前快捷鍵：" : "Current Hotkey: "
        case .hotkeyDescription:
            return language == "zh" ? "在任何 app 中按住此快捷鍵即可開始錄音" : "Hold this hotkey in any app to start recording"

        // AI 潤飾
        case .aiPolish:
            return language == "zh" ? "AI 文字潤飾" : "AI Text Polishing"
        case .enableAIPolish:
            return language == "zh" ? "啟用 AI 潤飾（使用 GPT-5-mini）" : "Enable AI Polishing (using GPT-5-mini)"
        case .aiPolishDescription:
            return language == "zh" ? "移除口語贅字、修正文法、優化句子結構" : "Remove filler words, fix grammar, optimize sentence structure"
        case .customSystemPrompt:
            return language == "zh" ? "自訂 System Prompt（選填）" : "Custom System Prompt (Optional)"
        case .useDefaultPrompt:
            return language == "zh" ? "使用預設 Prompt" : "Use Default Prompt"
        case .clear:
            return language == "zh" ? "清空" : "Clear"
        case .emptyForDefault:
            return language == "zh" ? "留空則使用預設 prompt" : "Leave empty to use default prompt"

        // 貼上設定
        case .pasteSettings:
            return language == "zh" ? "貼上設定" : "Paste Settings"
        case .autoPaste:
            return language == "zh" ? "自動貼上轉錄文字" : "Auto-paste transcribed text"
        case .restoreClipboard:
            return language == "zh" ? "貼上後還原剪貼簿" : "Restore clipboard after pasting"
        case .pasteDescription:
            return language == "zh" ? "轉錄完成後自動將文字貼到當前游標位置" : "Automatically paste text to cursor position after transcription"

        // 按鈕
        case .close:
            return language == "zh" ? "關閉" : "Close"
        case .saveAndClose:
            return language == "zh" ? "儲存並關閉" : "Save and Close"
        case .settingsSaved:
            return language == "zh" ? "設定已儲存" : "Settings Saved"
        case .ok:
            return language == "zh" ? "確定" : "OK"
        case .autoSaveHint:
            return language == "zh" ? "關閉視窗時會自動儲存設定" : "Settings will be saved automatically when closing"

        // Menu Bar
        case .status:
            return language == "zh" ? "狀態：" : "Status: "
        case .idle:
            return language == "zh" ? "待機" : "Idle"
        case .recording:
            return language == "zh" ? "錄音中..." : "Recording..."
        case .processing:
            return language == "zh" ? "處理中..." : "Processing..."
        case .holdFnSpace:
            return language == "zh" ? "💡 按住 Fn+Space 開始錄音" : "💡 Hold Fn+Space to start recording"
        case .recordingHint:
            return language == "zh" ? "🎤 錄音中...（放開 Fn+Space 停止）" : "🎤 Recording... (Release Fn+Space to stop)"
        case .processingHint:
            return language == "zh" ? "⏳ 處理中..." : "⏳ Processing..."
        case .lastTranscription:
            return language == "zh" ? "最後轉錄：" : "Last Transcription: "
        case .needAPIKey:
            return language == "zh" ? "⚠️ 請先設定 OpenAI API Key" : "⚠️ Please set OpenAI API Key first"
        case .needAccessibility:
            return language == "zh" ? "⚠️ 需要授予輔助使用權限" : "⚠️ Accessibility permission required"
        case .settingsMenu:
            return language == "zh" ? "設定..." : "Settings..."
        case .about:
            return language == "zh" ? "關於 LaSay" : "About LaSay"
        case .quit:
            return language == "zh" ? "結束 LaSay" : "Quit LaSay"

        // 關於對話框
        case .aboutTitle:
            return language == "zh" ? "LaSay" : "LaSay"
        case .aboutDescription:
            return language == "zh" ? """
            macOS 系統級語音輸入工具

            版本：%@ (Build %@)

            功能：
            • Whisper 語音轉錄
            • GPT-5-mini AI 文字潤飾
            • 全域快捷鍵：Fn + Space
            """ : """
            macOS System-wide Voice Input Tool

            Version: %@ (Build %@)

            Features:
            • Whisper Speech Transcription
            • GPT-5-mini AI Text Polishing
            • Global Hotkey: Fn + Space
            """

        // 權限對話框
        case .microphonePermissionTitle:
            return language == "zh" ? "需要麥克風權限" : "Microphone Permission Required"
        case .microphonePermissionMessage:
            return language == "zh" ? "LaSay 需要麥克風權限才能錄音。請在系統設定中允許麥克風存取。" : "LaSay needs microphone access to record audio. Please allow microphone access in System Settings."
        case .openSystemSettings:
            return language == "zh" ? "打開系統設定" : "Open System Settings"

        case .accessibilityPermissionTitle:
            return language == "zh" ? "需要輔助使用權限" : "Accessibility Permission Required"
        case .accessibilityPermissionMessage:
            return language == "zh" ? "LaSay 需要輔助使用權限才能監聽全域快捷鍵。\n\n請在系統設定中允許 LaSay。" : "LaSay needs accessibility permission to monitor global hotkeys.\n\nPlease allow LaSay in System Settings."
        case .accessibilityGrantedTitle:
            return language == "zh" ? "權限已授予" : "Permission Granted"
        case .accessibilityGrantedMessage:
            return language == "zh" ? "輔助使用權限已授予。\n\nLaSay 需要重新啟動才能生效。" : "Accessibility permission has been granted.\n\nLaSay needs to restart for changes to take effect."
        case .restartNow:
            return language == "zh" ? "立即重啟" : "Restart Now"
        case .restartLater:
            return language == "zh" ? "稍後重啟" : "Restart Later"

        // 通知
        case .transcriptionFailed:
            return language == "zh" ? "語音轉錄失敗" : "Transcription Failed"
        case .aiPolishFailed:
            return language == "zh" ? "AI 潤飾失敗" : "AI Polishing Failed"
        case .usingOriginalText:
            return language == "zh" ? "已使用原始轉錄文字：" : "Using original transcription: "
        }
    }
}

enum LocalizationKey {
    // 設定視窗
    case settings
    case openAIAPIKey
    case apiKeySet
    case show
    case hide
    case update
    case cancel
    case enterAPIKey
    case apiKeyDescription

    // 介面語言
    case uiLanguage
    case language
    case autoDetectLanguage

    // 快捷鍵
    case globalHotkey
    case currentHotkey
    case hotkeyDescription

    // AI 潤飾
    case aiPolish
    case enableAIPolish
    case aiPolishDescription
    case customSystemPrompt
    case useDefaultPrompt
    case clear
    case emptyForDefault

    // 貼上設定
    case pasteSettings
    case autoPaste
    case restoreClipboard
    case pasteDescription

    // 按鈕
    case close
    case saveAndClose
    case settingsSaved
    case ok
    case autoSaveHint

    // Menu Bar
    case status
    case idle
    case recording
    case processing
    case holdFnSpace
    case recordingHint
    case processingHint
    case lastTranscription
    case needAPIKey
    case needAccessibility
    case settingsMenu
    case about
    case quit

    // 關於對話框
    case aboutTitle
    case aboutDescription

    // 權限對話框
    case microphonePermissionTitle
    case microphonePermissionMessage
    case openSystemSettings
    case accessibilityPermissionTitle
    case accessibilityPermissionMessage
    case accessibilityGrantedTitle
    case accessibilityGrantedMessage
    case restartNow
    case restartLater

    // 通知
    case transcriptionFailed
    case aiPolishFailed
    case usingOriginalText
}
