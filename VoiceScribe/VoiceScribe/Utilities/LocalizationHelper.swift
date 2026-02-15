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
        case .generalTab:
            return language == "zh" ? "一般" : "General"
        case .transcriptionTab:
            return language == "zh" ? "轉錄" : "Transcription"
        case .aiPolishTab:
            return language == "zh" ? "AI 潤飾" : "AI Polish"
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
        case .save:
            return language == "zh" ? "儲存" : "Save"
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
        case .languageChineseLabel:
            return "繁體中文 (Chinese)"
        case .languageEnglishLabel:
            return "English (英文)"
        case .autoDetectLanguage:
            return language == "zh" ? "語音轉錄會自動辨識所有語言" : "Speech transcription automatically detects all languages"

        // 語音轉錄
        case .transcriptionSettings:
            return language == "zh" ? "語音轉錄" : "Transcription"
        case .transcriptionMode:
            return language == "zh" ? "轉錄模式" : "Mode"
        case .transcriptionLanguage:
            return language == "zh" ? "轉錄語言" : "Language"
        case .transcriptionDescription:
            return language == "zh" ? "本地模式使用 whisper.cpp（可離線），雲端模式使用 OpenAI API" : "Local uses whisper.cpp (offline), Cloud uses OpenAI API"
        case .modelDownloaded:
            return language == "zh" ? "Model: ggml-base (142MB) ✅ 已下載" : "Model: ggml-base (142MB) ✅ Downloaded"
        case .modelNotDownloaded:
            return language == "zh" ? "Model: ggml-base ⬇️ 尚未下載（首次使用時下載）" : "Model: ggml-base ⬇️ Not downloaded (will download on first use)"
        case .cliDownloaded:
            return language == "zh" ? "Whisper CLI: ✅ 已下載" : "Whisper CLI: ✅ Downloaded"
        case .cliNotDownloaded:
            return language == "zh" ? "Whisper CLI: ⬇️ 尚未下載（首次使用時下載）" : "Whisper CLI: ⬇️ Not downloaded (will download on first use)"

        // 快捷鍵
        case .globalHotkey:
            return language == "zh" ? "全域快捷鍵" : "Global Hotkey"
        case .currentHotkey:
            return language == "zh" ? "當前快捷鍵：" : "Current Hotkey: "
        case .hotkeyDescription:
            return language == "zh" ? "在任何 app 中按住此快捷鍵即可開始錄音" : "Hold this hotkey in any app to start recording"
        case .hotkeyComingSoon:
            return language == "zh" ? "自訂快捷鍵將在未來更新中支援" : "Custom hotkey support coming in a future update"

        // AI 潤飾
        case .aiPolish:
            return language == "zh" ? "AI 文字潤飾" : "AI Text Polishing"
        case .enableAIPolish:
            return language == "zh" ? "啟用 AI 潤飾（使用 GPT-5-mini）" : "Enable AI Polishing (using GPT-5-mini)"
        case .aiPolishDescription:
            return language == "zh" ? "移除口語贅字、修正文法、優化句子結構" : "Remove filler words, fix grammar, optimize sentence structure"
        case .currentPromptStatus:
            return language == "zh" ? "目前使用：%@" : "Current prompt: %@"
        case .defaultPromptLabel:
            return language == "zh" ? "預設" : "Default"
        case .customPromptLabel:
            return language == "zh" ? "自訂" : "Custom"
        case .customPromptHint:
            return language == "zh" ? "你可以在這裡自訂 AI 潤飾的指令" : "You can customize the AI polish instructions here"
        case .customSystemPrompt:
            return language == "zh" ? "自訂 System Prompt（選填）" : "Custom System Prompt (Optional)"
        case .resetToDefault:
            return language == "zh" ? "重設為預設" : "Reset to Default"

        // 貼上設定
        case .pasteSettings:
            return language == "zh" ? "貼上設定" : "Paste Settings"
        case .autoPaste:
            return language == "zh" ? "自動貼上轉錄文字" : "Auto-paste transcribed text"
        case .restoreClipboard:
            return language == "zh" ? "貼上後還原剪貼簿" : "Restore clipboard after pasting"
        case .previewBeforePaste:
            return language == "zh" ? "貼上前預覽" : "Preview before paste"
        case .soundFeedback:
            return language == "zh" ? "音效回饋" : "Sound Feedback"
        case .pasteDescription:
            return language == "zh" ? "轉錄完成後自動將文字貼到當前游標位置" : "Automatically paste text to cursor position after transcription"

        // 按鈕
        case .close:
            return language == "zh" ? "關閉" : "Close"
        case .ok:
            return language == "zh" ? "確定" : "OK"
        case .paste:
            return language == "zh" ? "貼上" : "Paste"
        case .changesSavedAutomatically:
            return language == "zh" ? "變更會自動儲存" : "Changes are saved automatically"
        case .back:
            return language == "zh" ? "返回" : "Back"
        case .next:
            return language == "zh" ? "下一步" : "Next"
        case .finish:
            return language == "zh" ? "完成" : "Finish"

        // Menu Bar
        case .status:
            return language == "zh" ? "狀態：" : "Status: "
        case .modeLabel:
            return language == "zh" ? "模式：" : "Mode: "
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

        // 視窗標題
        case .settingsWindowTitle:
            return language == "zh" ? "LaSay 設定" : "LaSay Settings"
        case .onboardingWindowTitle:
            return language == "zh" ? "歡迎使用" : "Welcome"

        // 關於對話框
        case .aboutTitle:
            return language == "zh" ? "LaSay" : "LaSay"
        case .aboutDescription:
            return language == "zh" ? """
            macOS 系統級語音輸入工具

            版本：%@ (Build %@) - 測試版

            功能：
            • Whisper 語音轉錄
            • GPT-5-mini AI 文字潤飾
            • 全域快捷鍵：Fn + Space

            隱私：
            • 不收集任何使用資料
            • 所有處理透過 OpenAI API
            • API Key 安全儲存於本機

            聯繫方式：
            • Email: tamio.tsiu@gmail.com
            """ : """
            macOS System-wide Voice Input Tool

            Version: %@ (Build %@) - Beta

            Features:
            • Whisper Speech Transcription
            • GPT-5-mini AI Text Polishing
            • Global Hotkey: Fn + Space

            Privacy:
            • No data collection
            • All processing via OpenAI API
            • API Key stored securely locally

            Contact:
            • Email: tamio.tsiu@gmail.com
            """

        // Onboarding
        case .onboardingLanguageTitle:
            return language == "zh" ? "選擇語言" : "Select Language"
        case .onboardingWelcomeTitle:
            return language == "zh" ? "歡迎使用 LaSay" : "Welcome to LaSay"
        case .onboardingWelcomeDescription:
            return language == "zh"
                ? "LaSay 是你的系統級語音輸入工具，按住 Fn + Space 就能在任何 app 輸入。"
                : "LaSay is a system-wide voice input tool. Hold Fn + Space to dictate anywhere."
        case .onboardingChooseMode:
            return language == "zh" ? "選擇模式" : "Choose a mode"
        case .onboardingLocalMode:
            return language == "zh" ? "本地（免費）" : "Local (Free)"
        case .onboardingCloudMode:
            return language == "zh" ? "雲端（需要 API Key）" : "Cloud (API Key required)"
        case .onboardingPermissionsTitle:
            return language == "zh" ? "權限設定" : "Permissions"
        case .onboardingPermissionsDescription:
            return language == "zh"
                ? "LaSay 需要麥克風與輔助使用權限才能正常工作。"
                : "LaSay needs microphone and accessibility permissions to work properly."
        case .onboardingMicrophone:
            return language == "zh" ? "麥克風" : "Microphone"
        case .onboardingAccessibility:
            return language == "zh" ? "輔助使用" : "Accessibility"
        case .onboardingGrantMicrophone:
            return language == "zh" ? "授予麥克風權限" : "Grant Microphone Access"
        case .onboardingOpenAccessibility:
            return language == "zh" ? "打開輔助使用設定" : "Open Accessibility Settings"
        case .onboardingRecheckAccessibility:
            return language == "zh" ? "我已授權，重新檢查" : "I granted it, recheck"
        case .onboardingTryItTitle:
            return language == "zh" ? "試試看" : "Try it out"
        case .onboardingTryItPrompt:
            return language == "zh" ? "按住 Fn + Space 試試看！" : "Hold Fn + Space and give it a try!"
        case .onboardingTryItDescription:
            return language == "zh" ? "完成後就可以開始使用 LaSay。" : "You're all set to start using LaSay."

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
        case .modelDownloadFailed:
            return language == "zh" ? "模型下載失敗" : "Model download failed"
        case .noNetworkConnection:
            return language == "zh" ? "無網路連接" : "No internet connection"
        case .invalidAPIKey:
            return language == "zh" ? "API Key 無效" : "Invalid API Key"
        case .networkErrorPrefix:
            return language == "zh" ? "網路錯誤：" : "Network error: "
        case .apiErrorPrefix:
            return language == "zh" ? "API 錯誤：" : "API error: "
        case .downloadingModel:
            return language == "zh" ? "正在下載語音模型" : "Downloading speech model"
        case .downloadingBinary:
            return language == "zh" ? "正在下載轉錄工具" : "Downloading transcription tool"
        case .downloadingTitle:
            return language == "zh" ? "下載中" : "Downloading"
        case .transcriptionResultTitle:
            return language == "zh" ? "轉錄結果" : "Transcription Result"
        }
    }
}

enum LocalizationKey {
    // 設定視窗
    case settings
    case generalTab
    case transcriptionTab
    case aiPolishTab
    case openAIAPIKey
    case apiKeySet
    case show
    case hide
    case update
    case save
    case cancel
    case enterAPIKey
    case apiKeyDescription

    // 介面語言
    case uiLanguage
    case language
    case languageChineseLabel
    case languageEnglishLabel
    case autoDetectLanguage

    // 語音轉錄
    case transcriptionSettings
    case transcriptionMode
    case transcriptionLanguage
    case transcriptionDescription
    case modelDownloaded
    case modelNotDownloaded
    case cliDownloaded
    case cliNotDownloaded

    // 快捷鍵
    case globalHotkey
    case currentHotkey
    case hotkeyDescription
    case hotkeyComingSoon

    // AI 潤飾
    case aiPolish
    case enableAIPolish
    case aiPolishDescription
    case currentPromptStatus
    case defaultPromptLabel
    case customPromptLabel
    case customPromptHint
    case customSystemPrompt
    case resetToDefault

    // 貼上設定
    case pasteSettings
    case autoPaste
    case restoreClipboard
    case previewBeforePaste
    case soundFeedback
    case pasteDescription

    // 按鈕
    case close
    case ok
    case paste
    case changesSavedAutomatically
    case back
    case next
    case finish

    // Menu Bar
    case status
    case modeLabel
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

    // 視窗標題
    case settingsWindowTitle
    case onboardingWindowTitle

    // 關於對話框
    case aboutTitle
    case aboutDescription

    // Onboarding
    case onboardingLanguageTitle
    case onboardingWelcomeTitle
    case onboardingWelcomeDescription
    case onboardingChooseMode
    case onboardingLocalMode
    case onboardingCloudMode
    case onboardingPermissionsTitle
    case onboardingPermissionsDescription
    case onboardingMicrophone
    case onboardingAccessibility
    case onboardingGrantMicrophone
    case onboardingOpenAccessibility
    case onboardingRecheckAccessibility
    case onboardingTryItTitle
    case onboardingTryItPrompt
    case onboardingTryItDescription

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
    case modelDownloadFailed
    case noNetworkConnection
    case invalidAPIKey
    case networkErrorPrefix
    case apiErrorPrefix
    case downloadingModel
    case downloadingBinary
    case downloadingTitle
    case transcriptionResultTitle
}
