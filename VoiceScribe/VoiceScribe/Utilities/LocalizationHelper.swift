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
            return language == "zh" ? "用於雲端語音轉錄與 AI 文字潤飾" : "Used for cloud transcription and AI text polishing"
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

        // 語音轉錄
        case .transcriptionSettings:
            return language == "zh" ? "語音轉錄" : "Transcription"
        case .transcriptionMode:
            return language == "zh" ? "轉錄模式" : "Mode"
        case .transcriptionLanguage:
            return language == "zh" ? "轉錄語言" : "Language"
        case .transcriptionDescription:
            return language == "zh" ? "SenseVoice 離線辨識，雲端使用 OpenAI API" : "SenseVoice works offline, Cloud uses OpenAI API"

        // 快捷鍵

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
        case .idle:
            return language == "zh" ? "待機" : "Idle"
        case .recording:
            return language == "zh" ? "錄音中..." : "Recording..."
        case .processing:
            return language == "zh" ? "處理中..." : "Processing..."
        case .lastTranscription:
            return language == "zh" ? "最後轉錄：" : "Last Transcription: "
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

        // Onboarding
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
            return language == "zh" ? "找不到語音模型" : "Voice model not found"
        case .noNetworkConnection:
            return language == "zh" ? "無網路連接" : "No internet connection"
        case .invalidAPIKey:
            return language == "zh" ? "API Key 無效" : "Invalid API Key"
        case .apiErrorPrefix:
            return language == "zh" ? "API 錯誤：" : "API error: "
        case .apiKeyRequiredTitle:
            return language == "zh" ? "需要 API Key" : "API Key Required"
        case .apiKeyRequiredBody:
            return language == "zh" ? "請在設定中輸入 OpenAI API Key 以使用雲端模式" : "Please set your OpenAI API Key in Settings to use Cloud mode."
        
        // Accessibility labels
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
        
        // Punctuation
        case .punctuationStyle:
            return language == "zh" ? "標點符號" : "Punctuation"
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

    // 語音轉錄
    case transcriptionSettings
    case transcriptionMode
    case transcriptionLanguage
    case transcriptionDescription

    // 快捷鍵

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
    case paste
    case changesSavedAutomatically
    case back
    case next
    case finish

    // Menu Bar
    case status
    case idle
    case recording
    case processing
    case lastTranscription
    case settingsMenu
    case about
    case quit

    // 視窗標題
    case settingsWindowTitle
    case onboardingWindowTitle

    // 關於對話框
    case aboutTitle

    // Onboarding
    case onboardingPermissionsTitle
    case onboardingPermissionsDescription
    case onboardingMicrophone
    case onboardingAccessibility
    case onboardingGrantMicrophone
    case onboardingOpenAccessibility
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
    case apiErrorPrefix
    case apiKeyRequiredTitle
    case apiKeyRequiredBody
    
    // Accessibility labels
    case languageButtonAccessibility
    case toggleAccessibilityHint
    case aiPolishAccessibility
    case apiKeyShowHideAccessibility
    case apiKeySaveAccessibility
    case settingsCloseAccessibility
    case onboardingNextAccessibility
    case onboardingBackAccessibility
    case onboardingFinishAccessibility
    case cancelButtonAccessibility
    case menuBarStatusAccessibility
    
    // Error messages
    case microphonePermissionDenied
    case offlineCloudModeError
    case networkErrorActionable
    case invalidAPIKeyActionable
    case processingTimeout
    
    // Punctuation
    case punctuationStyle
}
