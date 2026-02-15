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
    @State private var refreshUI: Bool = false

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
                    Button(localization.localized(.back)) {
                        step -= 1
                    }
                }

                Spacer()

                if step < 2 {
                    Button(localization.localized(.next)) {
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(localization.localized(.finish)) {
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(28)
        .frame(width: 520, height: 360)
        .id(refreshUI)
        .onAppear {
            applyDefaultLanguageIfNeeded()
            loadMode()
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.onboardingLanguageTitle))
                    .font(.headline)

                HStack(spacing: 12) {
                    languageSelectionButton(title: "🇹🇼 繁體中文", code: "zh")
                    languageSelectionButton(title: "🇺🇸 English", code: "en")
                }
            }

            Divider()

            Text(localization.localized(.onboardingWelcomeTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingWelcomeDescription))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.onboardingChooseMode))
                    .font(.headline)

                Picker("", selection: $selectedMode) {
                    Text(localization.localized(.onboardingLocalMode)).tag(TranscriptionMode.local)
                    Text(localization.localized(.onboardingCloudMode)).tag(TranscriptionMode.cloud)
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
            Text(localization.localized(.onboardingPermissionsTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingPermissionsDescription))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.localized(.onboardingMicrophone))
                        .font(.headline)
                    Spacer()
                    Text(microphoneGranted ? "✅" : "⚪️")
                }

                Button(localization.localized(.onboardingGrantMicrophone)) {
                    AudioRecorder.shared.requestMicrophonePermission { granted in
                        microphoneGranted = granted
                    }
                }
                .buttonStyle(.bordered)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.localized(.onboardingAccessibility))
                        .font(.headline)
                    Spacer()
                    Text(accessibilityGranted ? "✅" : "⚪️")
                }

                Button(localization.localized(.onboardingOpenAccessibility)) {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)

                Button(localization.localized(.onboardingRecheckAccessibility)) {
                    accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var tryItStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.onboardingTryItTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingTryItPrompt))
                .font(.headline)

            Text(localization.localized(.onboardingTryItDescription))
                .foregroundColor(.secondary)
        }
    }

    private func languageSelectionButton(title: String, code: String) -> some View {
        Button(action: {
            UserDefaults.standard.set(code, forKey: "ui_language")
            refreshUI.toggle()
            NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
        }) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(localization.currentLanguage == code ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundColor(localization.currentLanguage == code ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func applyDefaultLanguageIfNeeded() {
        guard UserDefaults.standard.string(forKey: "ui_language") == nil else { return }
        let localeCode = Locale.current.language.languageCode?.identifier ?? Locale.current.languageCode ?? "en"
        let normalized = localeCode.lowercased()
        let defaultLanguage = normalized.hasPrefix("zh") ? "zh" : "en"
        UserDefaults.standard.set(defaultLanguage, forKey: "ui_language")
        refreshUI.toggle()
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
