//
//  LocalizationHelper.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/26.
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
            return language == "zh" ? "已設定 API Key" : "API Key Set"
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
        case .getAPIKey:
            return language == "zh" ? "取得 API Key → platform.openai.com" : "Get API Key → platform.openai.com"

        // 介面語言
        case .uiLanguage:
            return language == "zh" ? "介面語言" : "Interface Language"
        case .language:
            return language == "zh" ? "語言" : "Language"
        case .languageChineseLabel:
            return "繁體中文"
        case .languageEnglishLabel:
            return "English"
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
            return language == "zh" ? "Model: ggml-base (142MB) 已下載" : "Model: ggml-base (142MB) Downloaded"
        case .modelNotDownloaded:
            return language == "zh" ? "Model: ggml-base 尚未下載（首次使用時下載）" : "Model: ggml-base Not downloaded (will download on first use)"
        case .cliDownloaded:
            return language == "zh" ? "Whisper CLI: 已下載" : "Whisper CLI: Downloaded"
        case .cliNotDownloaded:
            return language == "zh" ? "Whisper CLI: 尚未下載（首次使用時下載）" : "Whisper CLI: Not downloaded (will download on first use)"

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
        case .advanced:
            return language == "zh" ? "進階設定" : "Advanced"
        case .aiCleanupDetail:
            return language == "zh" ? "AI 清理：移除贅字、修正文法、保留技術術語" : "AI cleanup: removes filler words, fixes grammar, preserves technical terms"

        // 按鈕
        case .close:
            return language == "zh" ? "關閉" : "Close"
        case .ok:
            return language == "zh" ? "確定" : "OK"
        case .paste:
            return language == "zh" ? "貼上" : "Paste"
        case .changesSavedAutomatically:
            return language == "zh" ? "自動儲存（API Key 除外）" : "Auto-saved (API Key excluded)"
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
            return language == "zh" ? "按住 Fn+Space 開始錄音" : "Hold Fn+Space to start recording"
        case .recordingHint:
            return language == "zh" ? "錄音中...（放開 Fn+Space 停止）" : "Recording... (Release Fn+Space to stop)"
        case .processingHint:
            return language == "zh" ? "處理中..." : "Processing..."
        case .lastTranscription:
            return language == "zh" ? "最後轉錄：" : "Last Transcription: "
        case .needAPIKey:
            return language == "zh" ? "請先設定 OpenAI API Key" : "Please set OpenAI API Key first"
        case .needAccessibility:
            return language == "zh" ? "需要授予輔助使用權限" : "Accessibility permission required"
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

            版本：%@ (%@) Beta

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

            Version: %@ (%@) Beta

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
        case .apiKeyRequiredTitle:
            return language == "zh" ? "需要 API Key" : "API Key Required"
        case .apiKeyRequiredBody:
            return language == "zh" ? "請在設定中輸入 OpenAI API Key 以使用雲端模式" : "Please set your OpenAI API Key in Settings to use Cloud mode."
        
        // Accessibility labels
        case .settingsTabAccessibility:
            return language == "zh" ? "設定分頁" : "Settings tab"
        case .generalTabAccessibility:
            return language == "zh" ? "一般設定分頁" : "General settings tab"
        case .transcriptionTabAccessibility:
            return language == "zh" ? "轉錄設定分頁" : "Transcription settings tab"
        case .aiPolishTabAccessibility:
            return language == "zh" ? "AI 潤飾設定分頁" : "AI polish settings tab"
        case .languageButtonAccessibility:
            return language == "zh" ? "語言選擇按鈕" : "Language selection button"
        case .toggleAccessibilityHint:
            return language == "zh" ? "點擊以切換" : "Tap to toggle"
        case .aiPolishAccessibility:
            return language == "zh" ? "AI 潤飾開關" : "AI polish toggle"
        case .apiKeyShowHideAccessibility:
            return language == "zh" ? "顯示或隱藏 API Key" : "Show or hide API Key"
        case .apiKeySaveAccessibility:
            return language == "zh" ? "儲存 API Key" : "Save API Key"
        case .settingsCloseAccessibility:
            return language == "zh" ? "關閉設定視窗" : "Close settings window"
        case .onboardingNextAccessibility:
            return language == "zh" ? "前往下一步" : "Go to next step"
        case .onboardingBackAccessibility:
            return language == "zh" ? "返回上一步" : "Go back to previous step"
        case .onboardingFinishAccessibility:
            return language == "zh" ? "完成設定" : "Complete setup"
        case .onboardingSkipAccessibility:
            return language == "zh" ? "跳過設定" : "Skip setup"
        case .downloadProgressAccessibility:
            return language == "zh" ? "下載進度" : "Download progress"
        case .transcriptionPreviewAccessibility:
            return language == "zh" ? "轉錄文字預覽" : "Transcription preview"
        case .pasteButtonAccessibility:
            return language == "zh" ? "貼上文字" : "Paste text"
        case .cancelButtonAccessibility:
            return language == "zh" ? "取消" : "Cancel"
        case .menuBarStatusAccessibility:
            return language == "zh" ? "LaSay 語音輸入" : "LaSay voice input"
        
        // Error messages
        case .microphonePermissionDenied:
            return language == "zh" ? "麥克風權限被拒絕。請前往「系統設定 > 隱私權與安全性 > 麥克風」啟用權限。" : "Microphone access denied. Open System Settings > Privacy > Microphone to enable."
        case .offlineCloudModeError:
            return language == "zh" ? "無網路連接。請切換到本地模式或檢查網路連接。" : "No internet connection. Switch to Local mode or check your connection."
        case .networkErrorActionable:
            return language == "zh" ? "網路錯誤：無法連線至 API。檢查網路或切換至本地模式。" : "Network error: Cannot reach API. Check connection or switch to Local mode."
        case .invalidAPIKeyActionable:
            return language == "zh" ? "API Key 無效 (401)。前往設定更新 Key。" : "Invalid API key (401). Update in Settings."
        case .processingTimeout:
            return language == "zh" ? "處理逾時。請重試。" : "Processing timeout. Please try again."
        case .transcriptionComplete:
            return language == "zh" ? "轉錄完成" : "Transcription Complete"
        case .pastedToCursor:
            return language == "zh" ? "已貼上至游標位置" : "Pasted to Cursor"
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
    case getAPIKey

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
    case advanced
    case aiCleanupDetail

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
    case apiKeyRequiredTitle
    case apiKeyRequiredBody
    
    // Accessibility labels
    case settingsTabAccessibility
    case generalTabAccessibility
    case transcriptionTabAccessibility
    case aiPolishTabAccessibility
    case languageButtonAccessibility
    case toggleAccessibilityHint
    case aiPolishAccessibility
    case apiKeyShowHideAccessibility
    case apiKeySaveAccessibility
    case settingsCloseAccessibility
    case onboardingNextAccessibility
    case onboardingBackAccessibility
    case onboardingFinishAccessibility
    case onboardingSkipAccessibility
    case downloadProgressAccessibility
    case transcriptionPreviewAccessibility
    case pasteButtonAccessibility
    case cancelButtonAccessibility
    case menuBarStatusAccessibility
    
    // Error messages
    case microphonePermissionDenied
    case offlineCloudModeError
    case networkErrorActionable
    case invalidAPIKeyActionable
    case processingTimeout
    case transcriptionComplete
    case pastedToCursor
}
