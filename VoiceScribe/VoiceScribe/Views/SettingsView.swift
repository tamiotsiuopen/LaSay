//
//  SettingsView.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var apiKey: String = ""
    @State private var hasAPIKey: Bool = false
    @State private var showingAPIKeyInput: Bool = false
    @State private var selectedUILanguage: String = "zh"
    @State private var restoreClipboard: Bool = true
    @State private var autoPaste: Bool = true
    @State private var enableAIPolish: Bool = false
    @State private var customSystemPrompt: String = ""
    @State private var showingSaveAlert = false
    @State private var showAPIKey: Bool = false
    @State private var refreshUI: Bool = false  // 用於觸發 UI 刷新

    private let keychainHelper = KeychainHelper.shared
    private let openAIService = OpenAIService.shared
    private let localization = LocalizationHelper.shared

    let uiLanguages = [
        ("zh", "繁體中文"),
        ("en", "English")
    ]

    var body: some View {
        VStack(spacing: 20) {
            // 標題
            Text(localization.localized(.settings))
                .font(.title)
                .fontWeight(.bold)
                .id(refreshUI)  // 用於強制刷新

            Divider()

            // API Key 設定
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
                    .frame(width: 400)
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

                        // 立即保存按鈕
                        Button("Save") {
                            if !apiKey.isEmpty {
                                let success = keychainHelper.save(key: "openai_api_key", value: apiKey)
                                if success {
                                    hasAPIKey = true
                                    showingAPIKeyInput = false
                                    print("💾 [SettingsView] API Key 已保存")
                                    // 刷新 menu
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
                    .frame(width: 400)
                }

                Text(localization.localized(.apiKeyDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 介面語言設定
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.uiLanguage))
                    .font(.headline)

                Picker(localization.localized(.language), selection: $selectedUILanguage) {
                    ForEach(uiLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                .onChange(of: selectedUILanguage) { newValue in
                    // 儲存語言設定並刷新 UI
                    UserDefaults.standard.set(newValue, forKey: "ui_language")
                    refreshUI.toggle()
                }

                Text(localization.localized(.autoDetectLanguage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 快捷鍵設定
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
            }

            Divider()

            // AI 潤飾設定
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.aiPolish))
                    .font(.headline)

                Toggle(localization.localized(.enableAIPolish), isOn: $enableAIPolish)
                    .toggleStyle(.checkbox)
                    .onChange(of: enableAIPolish) { newValue in
                        // 立即保存 AI 潤飾設定
                        UserDefaults.standard.set(newValue, forKey: "enable_ai_polish")
                        print("💾 [SettingsView] AI 潤飾設定已保存：\(newValue)")
                    }

                Text(localization.localized(.aiPolishDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if enableAIPolish {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized(.customSystemPrompt))
                            .font(.subheadline)

                        TextEditor(text: $customSystemPrompt)
                            .frame(height: 80)
                            .font(.system(.body, design: .monospaced))
                            .border(Color.secondary.opacity(0.3))

                        HStack {
                            Button(localization.localized(.useDefaultPrompt)) {
                                customSystemPrompt = openAIService.getDefaultSystemPrompt()
                            }
                            .font(.caption)

                            Button(localization.localized(.clear)) {
                                customSystemPrompt = ""
                            }
                            .font(.caption)
                        }

                        Text(localization.localized(.emptyForDefault))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            Divider()

            // 貼上設定
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.pasteSettings))
                    .font(.headline)

                Toggle(localization.localized(.autoPaste), isOn: $autoPaste)
                    .toggleStyle(.checkbox)
                    .onChange(of: autoPaste) { newValue in
                        // 立即保存自動貼上設定
                        UserDefaults.standard.set(newValue, forKey: "auto_paste")
                        print("💾 [SettingsView] 自動貼上設定已保存：\(newValue)")
                    }

                Toggle(localization.localized(.restoreClipboard), isOn: $restoreClipboard)
                    .toggleStyle(.checkbox)
                    .disabled(!autoPaste)
                    .onChange(of: restoreClipboard) { newValue in
                        // 立即保存還原剪貼簿設定
                        UserDefaults.standard.set(newValue, forKey: "restore_clipboard")
                        print("💾 [SettingsView] 還原剪貼簿設定已保存：\(newValue)")
                    }

                Text(localization.localized(.pasteDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 按鈕
            HStack(spacing: 12) {
                Button(localization.localized(.close)) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(localization.localized(.saveAndClose)) {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }

            // 提示文字
            Text(localization.localized(.autoSaveHint))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(width: 550, height: enableAIPolish ? 650 : 550)
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettingsWithoutAlert()
        }
        .alert(localization.localized(.settingsSaved), isPresented: $showingSaveAlert) {
            Button(localization.localized(.ok)) {
                dismiss()
            }
        }
    }

    // MARK: - Methods

    func loadSettings() {
        print("🔍 [SettingsView] 開始載入設定...")

        loadAPIKey()

        // 載入介面語言設定
        if let savedUILanguage = UserDefaults.standard.string(forKey: "ui_language") {
            selectedUILanguage = savedUILanguage
        }

        // 載入 AI 潤飾設定
        let savedAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
        print("🔍 [SettingsView] UserDefaults 讀取 enable_ai_polish: \(savedAIPolish)")
        enableAIPolish = savedAIPolish
        print("🔍 [SettingsView] 設定 enableAIPolish 為: \(enableAIPolish)")

        if let savedPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt") {
            customSystemPrompt = savedPrompt
            print("🔍 [SettingsView] 載入自訂 prompt: \(savedPrompt.prefix(50))...")
        }

        // 載入貼上設定
        autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")
        // 如果是第一次運行，預設為 true
        if !UserDefaults.standard.bool(forKey: "has_launched_before") {
            autoPaste = true
        }

        restoreClipboard = UserDefaults.standard.bool(forKey: "restore_clipboard")
        if !UserDefaults.standard.bool(forKey: "has_launched_before") {
            restoreClipboard = true
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

    func saveSettings() {
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

        // 儲存 AI 潤飾設定
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")

        // 儲存貼上設定
        UserDefaults.standard.set(autoPaste, forKey: "auto_paste")
        UserDefaults.standard.set(restoreClipboard, forKey: "restore_clipboard")

        // 標記已經啟動過
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        // 通知 AppDelegate 刷新 menu
        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)

        showingSaveAlert = true
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

        // 儲存 AI 潤飾設定
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")

        // 儲存貼上設定
        UserDefaults.standard.set(autoPaste, forKey: "auto_paste")
        UserDefaults.standard.set(restoreClipboard, forKey: "restore_clipboard")

        // 標記已經啟動過
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        // 通知 AppDelegate 刷新 menu
        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)

        print("💾 設定已自動儲存")
    }
}

#Preview {
    SettingsView()
}
