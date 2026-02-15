//
//  OnboardingView.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step: Int = 0
    @State private var selectedMode: TranscriptionMode = .local
    @State private var microphoneGranted: Bool = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted: Bool = HotkeyManager.shared.checkAccessibilityPermission()

    private let localization = LocalizationHelper.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if step == 0 {
                welcomeStep
            } else if step == 1 {
                permissionsStep
            } else {
                tryItStep
            }

            Spacer()

            HStack {
                if step > 0 {
                    Button(localization.currentLanguage == "zh" ? "返回" : "Back") {
                        step -= 1
                    }
                }

                Spacer()

                if step < 2 {
                    Button(localization.currentLanguage == "zh" ? "下一步" : "Next") {
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(localization.currentLanguage == "zh" ? "完成" : "Finish") {
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(28)
        .frame(width: 520, height: 360)
        .onAppear {
            loadMode()
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.currentLanguage == "zh" ? "歡迎使用 LaSay" : "Welcome to LaSay")
                .font(.title)
                .fontWeight(.bold)

            Text(localization.currentLanguage == "zh"
                 ? "LaSay 是你的系統級語音輸入工具，按住 Fn + Space 就能在任何 app 輸入。"
                 : "LaSay is a system-wide voice input tool. Hold Fn + Space to dictate anywhere.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.currentLanguage == "zh" ? "選擇模式" : "Choose a mode")
                    .font(.headline)

                Picker("", selection: $selectedMode) {
                    Text(localization.currentLanguage == "zh" ? "本地（免費）" : "Local (Free)").tag(TranscriptionMode.local)
                    Text(localization.currentLanguage == "zh" ? "雲端（需要 API Key）" : "Cloud (API Key required)").tag(TranscriptionMode.cloud)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
                .onChange(of: selectedMode) { newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: "transcription_mode")
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
                }
            }
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.currentLanguage == "zh" ? "權限設定" : "Permissions")
                .font(.title)
                .fontWeight(.bold)

            Text(localization.currentLanguage == "zh"
                 ? "LaSay 需要麥克風與輔助使用權限才能正常工作。"
                 : "LaSay needs microphone and accessibility permissions to work properly.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.currentLanguage == "zh" ? "麥克風" : "Microphone")
                        .font(.headline)
                    Spacer()
                    Text(microphoneGranted ? "✅" : "⚪️")
                }

                Button(localization.currentLanguage == "zh" ? "授予麥克風權限" : "Grant Microphone Access") {
                    AudioRecorder.shared.requestMicrophonePermission { granted in
                        microphoneGranted = granted
                    }
                }
                .buttonStyle(.bordered)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.currentLanguage == "zh" ? "輔助使用" : "Accessibility")
                        .font(.headline)
                    Spacer()
                    Text(accessibilityGranted ? "✅" : "⚪️")
                }

                Button(localization.currentLanguage == "zh" ? "打開輔助使用設定" : "Open Accessibility Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)

                Button(localization.currentLanguage == "zh" ? "我已授權，重新檢查" : "I granted it, recheck") {
                    accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var tryItStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.currentLanguage == "zh" ? "試試看" : "Try it out")
                .font(.title)
                .fontWeight(.bold)

            Text(localization.currentLanguage == "zh"
                 ? "按住 Fn + Space 試試看！"
                 : "Hold Fn + Space and give it a try!")
                .font(.headline)

            Text(localization.currentLanguage == "zh"
                 ? "完成後就可以開始使用 LaSay。"
                 : "You're all set to start using LaSay.")
                .foregroundColor(.secondary)
        }
    }

    private func loadMode() {
        if let savedMode = UserDefaults.standard.string(forKey: "transcription_mode"),
           let mode = TranscriptionMode(rawValue: savedMode) {
            selectedMode = mode
        } else {
            selectedMode = .local
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
