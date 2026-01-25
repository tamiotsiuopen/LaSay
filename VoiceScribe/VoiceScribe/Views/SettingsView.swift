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
    @State private var selectedLanguage: String = "zh"
    @State private var restoreClipboard: Bool = true
    @State private var autoPaste: Bool = true
    @State private var enableAIPolish: Bool = false
    @State private var customSystemPrompt: String = ""
    @State private var showingSaveAlert = false

    private let keychainHelper = KeychainHelper.shared
    private let openAIService = OpenAIService.shared

    let languages = [
        ("zh", "繁體中文"),
        ("en", "English")
    ]

    var body: some View {
        VStack(spacing: 20) {
            // 標題
            Text("設定")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            // API Key 設定
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.headline)

                SecureField("請輸入 API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 400)

                Text("用於 Whisper 語音轉錄，請從 OpenAI 官網取得")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 語言設定
            VStack(alignment: .leading, spacing: 8) {
                Text("轉錄語言")
                    .font(.headline)

                Picker("語言", selection: $selectedLanguage) {
                    ForEach(languages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }

            Divider()

            // 快捷鍵設定
            VStack(alignment: .leading, spacing: 8) {
                Text("全域快捷鍵")
                    .font(.headline)

                HStack {
                    Text("當前快捷鍵：")
                    Text("Fn + Space")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                Text("在任何 app 中按住此快捷鍵即可開始錄音")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // AI 潤飾設定
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 文字潤飾")
                    .font(.headline)

                Toggle("啟用 AI 潤飾（使用 GPT-5-mini）", isOn: $enableAIPolish)
                    .toggleStyle(.checkbox)

                Text("移除口語贅字、修正文法、優化句子結構")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if enableAIPolish {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("自訂 System Prompt（選填）")
                            .font(.subheadline)

                        TextEditor(text: $customSystemPrompt)
                            .frame(height: 80)
                            .font(.system(.body, design: .monospaced))
                            .border(Color.secondary.opacity(0.3))

                        HStack {
                            Button("使用預設 Prompt") {
                                customSystemPrompt = openAIService.getDefaultSystemPrompt()
                            }
                            .font(.caption)

                            Button("清空") {
                                customSystemPrompt = ""
                            }
                            .font(.caption)
                        }

                        Text("留空則使用預設 prompt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            Divider()

            // 貼上設定
            VStack(alignment: .leading, spacing: 8) {
                Text("貼上設定")
                    .font(.headline)

                Toggle("自動貼上轉錄文字", isOn: $autoPaste)
                    .toggleStyle(.checkbox)

                Toggle("貼上後還原剪貼簿", isOn: $restoreClipboard)
                    .toggleStyle(.checkbox)
                    .disabled(!autoPaste)

                Text("轉錄完成後自動將文字貼到當前游標位置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 按鈕
            HStack(spacing: 12) {
                Button("關閉") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("儲存並關閉") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 550, height: enableAIPolish ? 650 : 550)
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettingsWithoutAlert()
        }
        .alert("設定已儲存", isPresented: $showingSaveAlert) {
            Button("確定") {
                dismiss()
            }
        }
    }

    // MARK: - Methods

    func loadSettings() {
        print("🔍 [SettingsView] 開始載入設定...")

        // 載入 API Key
        if let savedAPIKey = keychainHelper.get(key: "openai_api_key") {
            apiKey = savedAPIKey
        }

        // 載入語言設定
        if let savedLanguage = UserDefaults.standard.string(forKey: "transcription_language") {
            selectedLanguage = savedLanguage
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

    func saveSettings() {
        // 儲存 API Key
        if !apiKey.isEmpty {
            _ = keychainHelper.save(key: "openai_api_key", value: apiKey)
        }

        // 儲存語言設定
        UserDefaults.standard.set(selectedLanguage, forKey: "transcription_language")

        // 儲存 AI 潤飾設定
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")

        // 儲存貼上設定
        UserDefaults.standard.set(autoPaste, forKey: "auto_paste")
        UserDefaults.standard.set(restoreClipboard, forKey: "restore_clipboard")

        // 標記已經啟動過
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        showingSaveAlert = true
    }

    func saveSettingsWithoutAlert() {
        // 儲存 API Key
        if !apiKey.isEmpty {
            _ = keychainHelper.save(key: "openai_api_key", value: apiKey)
        }

        // 儲存語言設定
        UserDefaults.standard.set(selectedLanguage, forKey: "transcription_language")

        // 儲存 AI 潤飾設定
        UserDefaults.standard.set(enableAIPolish, forKey: "enable_ai_polish")
        UserDefaults.standard.set(customSystemPrompt, forKey: "custom_system_prompt")

        // 儲存貼上設定
        UserDefaults.standard.set(autoPaste, forKey: "auto_paste")
        UserDefaults.standard.set(restoreClipboard, forKey: "restore_clipboard")

        // 標記已經啟動過
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        print("💾 設定已自動儲存")
    }
}

#Preview {
    SettingsView()
}
