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

    func localized(_ key: LocalizationKey) -> String {
        switch key {
        // 設定視窗
        case .settings: return "設定"
        case .openAIAPIKey: return "OpenAI API Key"
        case .apiKeySet: return "已設定 API Key"
        case .show: return "顯示"
        case .hide: return "隱藏"
        case .update: return "更新"
        case .save: return "儲存"
        case .cancel: return "取消"
        case .enterAPIKey: return "請輸入 API Key (sk-...)"
        case .apiKeyDescription: return "用於雲端語音轉錄與 AI 文字潤飾"
        case .getAPIKey: return "取得 API Key → platform.openai.com"

        // 語音轉錄
        case .transcriptionSettings: return "語音轉錄"
        case .transcriptionMode: return "轉錄模式"
        case .transcriptionLanguage: return "轉錄語言"
        case .transcriptionDescription: return "SenseVoice 離線辨識，雲端使用 OpenAI API"

        // AI 潤飾
        case .aiPolish: return "AI 文字潤飾"
        case .enableAIPolish: return "啟用 AI 潤飾（使用 GPT-4.1-mini）"
        case .aiPolishDescription: return "移除口語贅字、修正文法、優化句子結構"
        case .currentPromptStatus: return "目前使用：%@"
        case .defaultPromptLabel: return "預設"
        case .customPromptLabel: return "自訂"
        case .customPromptHint: return "你可以在這裡自訂 AI 潤飾的指令"
        case .customSystemPrompt: return "自訂 System Prompt（選填）"
        case .resetToDefault: return "重設為預設"
        case .advanced: return "進階設定"
        case .aiCleanupDetail: return "AI 清理：移除贅字、修正文法、保留技術術語"

        // 按鈕
        case .close: return "關閉"
        case .paste: return "貼上"
        case .changesSavedAutomatically: return "自動儲存（API Key 除外）"
        case .back: return "返回"
        case .next: return "下一步"
        case .finish: return "完成"

        // Menu Bar
        case .status: return "狀態："
        case .idle: return "待機"
        case .recording: return "錄音中..."
        case .processing: return "處理中..."
        case .lastTranscription: return "最後轉錄："
        case .settingsMenu: return "設定..."
        case .about: return "關於 LaSay"
        case .quit: return "結束 LaSay"

        // 視窗標題
        case .settingsWindowTitle: return "LaSay 設定"
        case .onboardingWindowTitle: return "歡迎使用"

        // 關於對話框
        case .aboutTitle: return "LaSay"

        // Onboarding
        case .onboardingPermissionsTitle: return "權限設定"
        case .onboardingPermissionsDescription: return "LaSay 需要麥克風與輔助使用權限才能正常工作。"
        case .onboardingMicrophone: return "麥克風"
        case .onboardingAccessibility: return "輔助使用"
        case .onboardingGrantMicrophone: return "授予麥克風權限"
        case .onboardingOpenAccessibility: return "打開輔助使用設定"
        case .onboardingTryItTitle: return "試試看"
        case .onboardingTryItPrompt: return "按住 Fn + Space 試試看！"
        case .onboardingTryItDescription: return "完成後就可以開始使用 LaSay。"

        // 權限對話框
        case .microphonePermissionTitle: return "需要麥克風權限"
        case .microphonePermissionMessage: return "LaSay 需要麥克風權限才能錄音。請在系統設定中允許麥克風存取。"
        case .openSystemSettings: return "打開系統設定"
        case .accessibilityPermissionTitle: return "需要輔助使用權限"
        case .accessibilityPermissionMessage: return "LaSay 需要輔助使用權限才能監聽全域快捷鍵。\n\n請在系統設定中允許 LaSay。"
        case .accessibilityGrantedTitle: return "權限已授予"
        case .accessibilityGrantedMessage: return "輔助使用權限已授予。\n\nLaSay 需要重新啟動才能生效。"
        case .restartNow: return "立即重啟"
        case .restartLater: return "稍後重啟"

        // 通知
        case .transcriptionFailed: return "語音轉錄失敗"
        case .aiPolishFailed: return "AI 潤飾失敗"
        case .usingOriginalText: return "已使用原始轉錄文字："
        case .modelDownloadFailed: return "找不到語音模型"
        case .noNetworkConnection: return "無網路連接"
        case .invalidAPIKey: return "API Key 無效"
        case .apiErrorPrefix: return "API 錯誤："
        case .apiKeyRequiredTitle: return "需要 API Key"
        case .apiKeyRequiredBody: return "請在設定中輸入 OpenAI API Key 以使用雲端模式"
        
        // Accessibility labels
        case .toggleAccessibilityHint: return "點擊以切換"
        case .aiPolishAccessibility: return "AI 潤飾開關"
        case .apiKeyShowHideAccessibility: return "顯示或隱藏 API Key"
        case .apiKeySaveAccessibility: return "儲存 API Key"
        case .settingsCloseAccessibility: return "關閉設定視窗"
        case .onboardingNextAccessibility: return "前往下一步"
        case .onboardingBackAccessibility: return "返回上一步"
        case .onboardingFinishAccessibility: return "完成設定"
        case .cancelButtonAccessibility: return "取消"
        case .menuBarStatusAccessibility: return "LaSay 語音輸入"
        
        // Error messages
        case .microphonePermissionDenied: return "麥克風權限被拒絕。請前往「系統設定 > 隱私權與安全性 > 麥克風」啟用權限。"
        case .offlineCloudModeError: return "無網路連接。請切換到本地模式或檢查網路連接。"
        case .networkErrorActionable: return "網路錯誤：無法連線至 API。檢查網路或切換至本地模式。"
        case .invalidAPIKeyActionable: return "API Key 無效 (401)。前往設定更新 Key。"
        case .processingTimeout: return "處理逾時。請重試。"
        
        // Punctuation
        case .punctuationStyle: return "標點符號"
        }
    }
}

enum LocalizationKey {
    // 設定視窗
    case settings, openAIAPIKey, apiKeySet, show, hide, update, save, cancel
    case enterAPIKey, apiKeyDescription, getAPIKey

    // 語音轉錄
    case transcriptionSettings, transcriptionMode, transcriptionLanguage, transcriptionDescription

    // AI 潤飾
    case aiPolish, enableAIPolish, aiPolishDescription
    case currentPromptStatus, defaultPromptLabel, customPromptLabel
    case customPromptHint, customSystemPrompt, resetToDefault, advanced, aiCleanupDetail

    // 按鈕
    case close, paste, changesSavedAutomatically, back, next, finish

    // Menu Bar
    case status, idle, recording, processing, lastTranscription, settingsMenu, about, quit

    // 視窗標題
    case settingsWindowTitle, onboardingWindowTitle

    // 關於對話框
    case aboutTitle

    // Onboarding
    case onboardingPermissionsTitle, onboardingPermissionsDescription
    case onboardingMicrophone, onboardingAccessibility
    case onboardingGrantMicrophone, onboardingOpenAccessibility
    case onboardingTryItTitle, onboardingTryItPrompt, onboardingTryItDescription

    // 權限對話框
    case microphonePermissionTitle, microphonePermissionMessage, openSystemSettings
    case accessibilityPermissionTitle, accessibilityPermissionMessage
    case accessibilityGrantedTitle, accessibilityGrantedMessage
    case restartNow, restartLater

    // 通知
    case transcriptionFailed, aiPolishFailed, usingOriginalText
    case modelDownloadFailed, noNetworkConnection, invalidAPIKey
    case apiErrorPrefix, apiKeyRequiredTitle, apiKeyRequiredBody
    
    // Accessibility
    case toggleAccessibilityHint, aiPolishAccessibility
    case apiKeyShowHideAccessibility, apiKeySaveAccessibility
    case settingsCloseAccessibility, onboardingNextAccessibility
    case onboardingBackAccessibility, onboardingFinishAccessibility
    case cancelButtonAccessibility, menuBarStatusAccessibility
    
    // Error messages
    case microphonePermissionDenied, offlineCloudModeError
    case networkErrorActionable, invalidAPIKeyActionable, processingTimeout
    
    // Punctuation
    case punctuationStyle
}
