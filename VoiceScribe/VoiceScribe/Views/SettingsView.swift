//
//  SettingsView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var apiKey: String = ""
    @State private var hasAPIKey: Bool = false
    @State private var showingAPIKeyInput: Bool = false
    @State private var selectedUILanguage: String = "zh"
    @State private var selectedTab: Int = 1
    @State private var autoPaste: Bool = true
    @State private var enableAIPolish: Bool = false
    @State private var customSystemPrompt: String = ""
    @State private var transcriptionMode: TranscriptionMode = .cloud
    @State private var transcriptionLanguage: TranscriptionLanguage = .auto
    @State private var showAPIKey: Bool = false
    @State private var enableSoundFeedback: Bool = true
    @State private var enablePreviewMode: Bool = false
    @State private var isPasteAdvancedExpanded: Bool = false
    @State private var isAIPolishAdvancedExpanded: Bool = false
    @State private var refreshUI: Bool = false  // 用於觸發 UI 刷新

    private var isUsingCustomPrompt: Bool {
        !customSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let keychainHelper = KeychainHelper.shared
    private let openAIService = OpenAIService.shared
    private let localWhisperService = LocalWhisperService.shared
    private let localization = LocalizationHelper.shared


    var body: some View {
        VStack(spacing: 16) {
            Text(localization.localized(.settings))
                .font(.title)
                .fontWeight(.bold)
                .id(refreshUI)

            Divider()

            TabView(selection: $selectedTab) {
                generalTab
                    .tabItem {
                        Text(localization.localized(.generalTab))
                    }
                    .tag(0)

                transcriptionTab
                    .tabItem {
                        Text(localization.localized(.transcriptionTab))
                    }
                    .tag(1)

                aiPolishTab
                    .tabItem {
                        Text(localization.localized(.aiPolishTab))
                    }
                    .tag(2)
            }

            Spacer()

            HStack {
                Text(localization.localized(.changesSavedAutomatically))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(localization.localized(.close)) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 500)
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettingsWithoutAlert()
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.uiLanguage))
                    .font(.headline)

                HStack(spacing: 12) {
                    languageSelectionButton(title: localization.localized(.languageChineseLabel), code: "zh")
                    languageSelectionButton(title: localization.localized(.languageEnglishLabel), code: "en")
                }
                .frame(maxWidth: 420)

                Text(localization.localized(.autoDetectLanguage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.globalHotkey))
                    .font(.headline)

                HStack {
                    Text(localization.localized(.currentHotkey))
                    Text("Fn + Space")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                Text(localization.localized(.hotkeyDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(localization.localized(.hotkeyComingSoon))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.pasteSettings))
                    .font(.headline)

                Toggle(localization.localized(.autoPaste), isOn: $autoPaste)
                    .toggleStyle(.checkbox)
                    .onChange(of: autoPaste) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "auto_paste")
                    }

                Toggle(localization.localized(.soundFeedback), isOn: $enableSoundFeedback)
                    .toggleStyle(.checkbox)
                    .onChange(of: enableSoundFeedback) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "enable_sound_feedback")
                    }

                DisclosureGroup(localization.localized(.advanced), isExpanded: $isPasteAdvancedExpanded) {
                    Toggle(localization.localized(.previewBeforePaste), isOn: $enablePreviewMode)
                        .toggleStyle(.checkbox)
                        .onChange(of: enablePreviewMode) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "enable_preview_mode")
                        }
                        .padding(.top, 4)
                }

                Text(localization.localized(.pasteDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }


    private func languageSelectionButton(title: String, code: String) -> some View {
        Button(action: {
            selectedUILanguage = code
            UserDefaults.standard.set(code, forKey: "ui_language")
            refreshUI.toggle()
            NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
        }) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .foregroundColor(selectedUILanguage == code ? .white : .primary)
                .background(selectedUILanguage == code ? Color.accentColor : Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var transcriptionTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.transcriptionSettings))
                    .font(.headline)

                HStack {
                    Text(localization.localized(.transcriptionMode))
                    Spacer()
                    Picker("", selection: $transcriptionMode) {
                        ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                            Text(mode.localizedDisplayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: transcriptionMode) { newValue in
                        UserDefaults.standard.set(newValue.rawValue, forKey: "transcription_mode")
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
                    }
                }

                HStack {
                    Text(localization.localized(.transcriptionLanguage))
                    Spacer()
                    Picker("", selection: $transcriptionLanguage) {
                        ForEach(TranscriptionLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: transcriptionLanguage) { newValue in
                        UserDefaults.standard.set(newValue.rawValue, forKey: "transcription_language")
                    }
                }

                Text(localization.localized(.transcriptionDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if transcriptionMode == .local {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized(localWhisperService.isModelDownloaded ? .modelDownloaded : .modelNotDownloaded))
                        Text(localization.localized(localWhisperService.isCLIDownloaded ? .cliDownloaded : .cliNotDownloaded))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Divider()

            apiKeySection
        }
        .padding(.top, 4)
    }

    private var aiPolishTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.aiPolish))
                    .font(.headline)

                Toggle(localization.localized(.enableAIPolish), isOn: $enableAIPolish)
                    .toggleStyle(.checkbox)
                    .onChange(of: enableAIPolish) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "enable_ai_polish")
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
                    }

                Text(localization.localized(.aiPolishDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if enableAIPolish {
                Text(localization.localized(.aiCleanupDetail))
                    .font(.caption)
                    .foregroundColor(.secondary)

                DisclosureGroup(localization.localized(.advanced), isExpanded: $isAIPolishAdvancedExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: localization.localized(.currentPromptStatus), isUsingCustomPrompt ? localization.localized(.customPromptLabel) : localization.localized(.defaultPromptLabel)))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(localization.localized(.customPromptHint))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(localization.localized(.customSystemPrompt))
                            .font(.subheadline)

                        ZStack(alignment: .topLeading) {
                            if !isUsingCustomPrompt {
                                Text(openAIService.getDefaultPromptSummary())
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.top, 8)
                                    .padding(.horizontal, 6)
                            }

                            TextEditor(text: $customSystemPrompt)
                                .frame(minHeight: 120, maxHeight: 180)
                                .font(.system(.body, design: .monospaced))
                                .border(Color.secondary.opacity(0.3))
                        }

                        HStack {
                            Button(localization.localized(.resetToDefault)) {
                                customSystemPrompt = ""
                            }
                            .font(.caption)

                            Spacer()
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.top, 4)
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.localized(.openAIAPIKey))
                .font(.headline)

            if hasAPIKey && !showingAPIKeyInput {
                HStack {
                    Text(localization.localized(.apiKeySet))
                        .foregroundColor(.green)

                    if showAPIKey {
                        Text(apiKey)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text("(\(apiKey.prefix(7))...\(apiKey.suffix(4)))")
                            .font(.system(.body, design: .monospaced))
                    }

                    Spacer()

                    Button(localization.localized(showAPIKey ? .hide : .show)) {
                        showAPIKey.toggle()
                    }
                    .font(.caption)

                    Button(localization.localized(.update)) {
                        showingAPIKeyInput = true
                    }
                    .font(.caption)
                }
                .frame(maxWidth: 420)
            } else {
                HStack {
                    if showAPIKey {
                        TextField(localization.localized(.enterAPIKey), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField(localization.localized(.enterAPIKey), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(localization.localized(showAPIKey ? .hide : .show)) {
                        showAPIKey.toggle()
                    }
                    .font(.caption)

                    Button(localization.localized(.save)) {
                        if !apiKey.isEmpty {
                            let success = keychainHelper.save(key: "openai_api_key", value: apiKey)
                            if success {
                                hasAPIKey = true
                                showingAPIKeyInput = false
                                NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
                            }
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)

                    if hasAPIKey {
                        Button(localization.localized(.cancel)) {
                            showingAPIKeyInput = false
                            loadAPIKey()
                        }
                        .font(.caption)
                    }
                }
                .frame(maxWidth: 420)
            }

            Text(localization.localized(.apiKeyDescription))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Methods

    func loadSettings() {
        debugLog("🔍 [SettingsView] 開始載入設定...")

        loadAPIKey()

        // 載入介面語言設定
        if let savedUILanguage = UserDefaults.standard.string(forKey: "ui_language") {
            selectedUILanguage = savedUILanguage
        }

        // 載入語音轉錄設定
        if let savedMode = UserDefaults.standard.string(forKey: "transcription_mode"),
           let mode = TranscriptionMode(rawValue: savedMode) {
            transcriptionMode = mode
        }

        if let savedLanguage = UserDefaults.standard.string(forKey: "transcription_language"),
           let language = TranscriptionLanguage(rawValue: savedLanguage) {
            transcriptionLanguage = language
        }

        // 載入 AI 潤飾設定
        let savedAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
        debugLog("🔍 [SettingsView] UserDefaults 讀取 enable_ai_polish: \(savedAIPolish)")
        enableAIPolish = savedAIPolish
        debugLog("🔍 [SettingsView] 設定 enableAIPolish 為: \(enableAIPolish)")


        if let savedPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt") {
            customSystemPrompt = savedPrompt
            debugLog("🔍 [SettingsView] 載入自訂 prompt: \(savedPrompt.prefix(50))...")
        }

        // 載入貼上設定
        autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")
        // 如果是第一次運行，預設為 true
        if !UserDefaults.standard.bool(forKey: "has_launched_before") {
            autoPaste = true
        }

        if UserDefaults.standard.object(forKey: "enable_sound_feedback") == nil {
            enableSoundFeedback = true
            UserDefaults.standard.set(true, forKey: "enable_sound_feedback")
        } else {
            enableSoundFeedback = UserDefaults.standard.bool(forKey: "enable_sound_feedback")
        }

        if UserDefaults.standard.object(forKey: "enable_preview_mode") == nil {
            enablePreviewMode = false
            UserDefaults.standard.set(false, forKey: "enable_preview_mode")
        } else {
            enablePreviewMode = UserDefaults.standard.bool(forKey: "enable_preview_mode")
        }
    }

    func loadAPIKey() {
        // 載入 API Key
        if let savedAPIKey = keychainHelper.get(key: "openai_api_key"), !savedAPIKey.isEmpty {
            apiKey = savedAPIKey
            hasAPIKey = true
            showingAPIKeyInput = false
        } else {
            apiKey = ""
            hasAPIKey = false
            showingAPIKeyInput = true
        }
    }

    func saveSettingsWithoutAlert() {
        // 儲存 API Key
        if !apiKey.isEmpty {
            let success = keychainHelper.save(key: "openai_api_key", value: apiKey)
            if success {
                hasAPIKey = true
                showingAPIKeyInput = false
            }
        }

        // 儲存介面語言設定
        UserDefaults.standard.set(selectedUILanguage, forKey: "ui_language")

        // 儲存語音轉錄設定
        UserDefaults.standard.set(transcriptionMode.rawValue, forKey: "transcription_mode")
        UserDefaults.standard.set(transcriptionLanguage.rawValue, forKey: "transcription_language")

        // 儲存 AI 潤飾設定
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")

        // 儲存貼上設定
        UserDefaults.standard.set(autoPaste, forKey: "auto_paste")
        UserDefaults.standard.set(enablePreviewMode, forKey: "enable_preview_mode")
        UserDefaults.standard.set(enableSoundFeedback, forKey: "enable_sound_feedback")

        // 標記已經啟動過
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        // 通知 AppDelegate 刷新 menu
        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)

        debugLog("💾 設定已自動儲存")
    }
}

#Preview {
    SettingsView()
}
