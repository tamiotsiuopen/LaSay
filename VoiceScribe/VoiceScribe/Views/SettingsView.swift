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
    @State private var enableAIPolish: Bool = false
    @State private var customSystemPrompt: String = ""
    @State private var transcriptionMode: TranscriptionMode = .cloud
    @State private var transcriptionLanguage: TranscriptionLanguage = .auto
    @State private var punctuationStyle: PunctuationStyle = .fullWidth
    @State private var showAPIKey: Bool = false
    @State private var isAIPolishAdvancedExpanded: Bool = false
    @State private var showDeleteAPIKeyConfirm: Bool = false
    @State private var isLoadingModel: Bool = false

    private var isUsingCustomPrompt: Bool {
        !customSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let keychainHelper = KeychainHelper.shared
    private let openAIService = OpenAIService.shared
    private let senseVoiceService = SenseVoiceService.shared
    private let localization = LocalizationHelper.shared

    var body: some View {
        VStack(spacing: 16) {
            Text(localization.localized(.settings))
                .font(.title)
                .fontWeight(.bold)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - 轉錄模式
                        transcriptionSection

                        Divider()

                        // MARK: - 標點符號
                        punctuationSection

                        Divider()

                        // MARK: - AI 潤飾
                        aiPolishSection

                        Divider()

                        // MARK: - API Key
                        apiKeySection
                            .id("apiKeySection")
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    loadSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !hasAPIKey && transcriptionMode == .cloud {
                            withAnimation {
                                proxy.scrollTo("apiKeySection", anchor: .top)
                            }
                        }
                    }
                }
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
                .accessibilityLabel(localization.localized(.settingsCloseAccessibility))
            }
        }
        .padding(24)
        .frame(minWidth: 500, idealWidth: 500, maxWidth: 500, minHeight: 400, maxHeight: 600)
        .onDisappear {
            saveSettingsWithoutAlert()
        }
    }

    // MARK: - Transcription Section

    private var transcriptionSection: some View {
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
                    if newValue == .senseVoice, !senseVoiceService.isModelLoaded {
                        isLoadingModel = true
                        senseVoiceService.preloadModel(completion: { _ in isLoadingModel = false })
                    }
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

            if transcriptionMode == .senseVoice && isLoadingModel {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("模型載入中…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Punctuation Section

    private var punctuationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.localized(.punctuationStyle))
                .font(.headline)

            Picker("", selection: $punctuationStyle) {
                ForEach(PunctuationStyle.allCases, id: \.self) { style in
                    Text(style.localizedDisplayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: punctuationStyle) { newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: "punctuation_style")
            }

            Text(punctuationExample)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var punctuationExample: String {
        switch punctuationStyle {
        case .fullWidth: return "範例：Hello，World。This is a test！"
        case .halfWidth: return "範例：Hello,World.This is a test!"
        case .spaces: return "範例：Hello World This is a test"
        }
    }

    // MARK: - AI Polish Section

    private var aiPolishSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.localized(.aiPolish))
                .font(.headline)

            Toggle(localization.localized(.enableAIPolish), isOn: $enableAIPolish)
                .toggleStyle(.checkbox)
                .accessibilityLabel(localization.localized(.aiPolishAccessibility))
                .accessibilityHint(localization.localized(.toggleAccessibilityHint))
                .accessibilityValue(enableAIPolish ? "已開啟" : "已關閉")
                .onChange(of: enableAIPolish) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "enable_ai_polish")
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
                }

            Text(localization.localized(.aiPolishDescription))
                .font(.caption)
                .foregroundColor(.secondary)

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
    }

    // MARK: - API Key Section

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
                    .accessibilityLabel(localization.localized(.apiKeyShowHideAccessibility))

                    Button(localization.localized(.update)) {
                        showingAPIKeyInput = true
                    }
                    .font(.caption)

                    Button("刪除") {
                        showDeleteAPIKeyConfirm = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .accessibilityLabel("刪除 API Key")
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
                    .accessibilityLabel(localization.localized(.apiKeyShowHideAccessibility))

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
                    .accessibilityLabel(localization.localized(.apiKeySaveAccessibility))

                    if hasAPIKey {
                        Button(localization.localized(.cancel)) {
                            showingAPIKeyInput = false
                            loadAPIKey()
                        }
                        .font(.caption)
                        .accessibilityLabel(localization.localized(.cancelButtonAccessibility))
                    }
                }
                .frame(maxWidth: 420)
            }

            Text(localization.localized(.apiKeyDescription))
                .font(.caption)
                .foregroundColor(.secondary)

            Link(localization.localized(.getAPIKey), destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(.caption)
        }
        .alert(
            "確定刪除 API Key？",
            isPresented: $showDeleteAPIKeyConfirm
        ) {
            Button("刪除", role: .destructive) {
                _ = keychainHelper.delete(key: "openai_api_key")
                apiKey = ""
                hasAPIKey = false
                showingAPIKeyInput = true
                showAPIKey = false
                NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("刪除後，雲端模式和 AI 潤飾將無法使用，直到重新輸入 API Key。")
        }
    }

    // MARK: - Methods

    func loadSettings() {
        loadAPIKey()

        transcriptionMode = TranscriptionMode.fromSaved(UserDefaults.standard.string(forKey: "transcription_mode"))

        if let savedLanguage = UserDefaults.standard.string(forKey: "transcription_language"),
           let language = TranscriptionLanguage(rawValue: savedLanguage) {
            transcriptionLanguage = language
        }

        if let savedPunctuation = UserDefaults.standard.string(forKey: "punctuation_style"),
           let style = PunctuationStyle(rawValue: savedPunctuation) {
            punctuationStyle = style
        }

        enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")

        if let savedPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt") {
            customSystemPrompt = savedPrompt
        }
    }

    func loadAPIKey() {
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
        if !apiKey.isEmpty {
            let success = keychainHelper.save(key: "openai_api_key", value: apiKey)
            if success {
                hasAPIKey = true
                showingAPIKeyInput = false
            }
        }

        UserDefaults.standard.set(transcriptionMode.rawValue, forKey: "transcription_mode")
        UserDefaults.standard.set(transcriptionLanguage.rawValue, forKey: "transcription_language")
        UserDefaults.standard.set(punctuationStyle.rawValue, forKey: "punctuation_style")
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
    }
}

#Preview {
    SettingsView()
}
