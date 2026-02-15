//
//  OnboardingView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step: Int = 0
    @State private var selectedMode: TranscriptionMode = .cloud
    @State private var microphoneGranted: Bool = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted: Bool = HotkeyManager.shared.checkAccessibilityPermission()
    @State private var refreshUI: Bool = false
    @State private var showDownloadConfirm: Bool = false

    private let localization = LocalizationHelper.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Button(localization.currentLanguage == "zh" ? "跳過" : "Skip") {
                    onFinish()
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
                .accessibilityLabel(localization.localized(.onboardingSkipAccessibility))
                .accessibilityHint("Skip onboarding and finish setup")
            }

            if step == 0 {
                languageStep
            } else if step == 1 {
                welcomeStep
            } else if step == 2 {
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
                    .accessibilityLabel(localization.localized(.onboardingBackAccessibility))
                    .accessibilityHint("Go to previous step")
                }

                Spacer()

                if step < 3 {
                    Button(localization.localized(.next)) {
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(localization.localized(.onboardingNextAccessibility))
                    .accessibilityHint("Continue to next step")
                } else {
                    Button(localization.localized(.finish)) {
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(localization.localized(.onboardingFinishAccessibility))
                    .accessibilityHint("Complete onboarding")
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
        .alert(
            localization.currentLanguage == "zh" ? "下載語音模型？" : "Download Voice Model?",
            isPresented: $showDownloadConfirm
        ) {
            Button(localization.currentLanguage == "zh" ? "立即下載 (142MB)" : "Download Now (142MB)") {
                DispatchQueue.global().async {
                    LocalWhisperService.shared.predownload()
                }
            }
            Button(localization.currentLanguage == "zh" ? "稍後再說" : "Later", role: .cancel) {}
        } message: {
            Text(localization.currentLanguage == "zh"
                 ? "本地模式需要下載語音辨識模型 (142MB)。要現在下載嗎？"
                 : "Local mode requires a voice recognition model (142MB). Download now?")
        }
    }

    private var languageStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text("Choose Language / 選擇語言")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 16) {
                languageSelectionButton(title: "繁體中文", code: "zh")
                    .accessibilityLabel("繁體中文")
                    .accessibilityHint(localization.localized(.languageButtonAccessibility))
                languageSelectionButton(title: "English", code: "en")
                    .accessibilityLabel("English")
                    .accessibilityHint(localization.localized(.languageButtonAccessibility))
            }
            .frame(maxWidth: 420)
            
            Spacer()
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.onboardingWelcomeTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingWelcomeDescription))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.onboardingChooseMode))
                    .font(.headline)

                Picker("", selection: $selectedMode) {
                    Text(localization.localized(.onboardingCloudMode)).tag(TranscriptionMode.cloud)
                    Text(localization.currentLanguage == "zh" ? "本地（實驗性）" : "Local (Experimental)").tag(TranscriptionMode.local)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
                .onChange(of: selectedMode) { newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: "transcription_mode")
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)

                    if newValue == .local && !LocalWhisperService.shared.isModelDownloaded {
                        showDownloadConfirm = true
                    }
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
                    if microphoneGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }

                Button(localization.localized(.onboardingGrantMicrophone)) {
                    AudioRecorder.shared.requestMicrophonePermission { granted in
                        microphoneGranted = granted
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(localization.localized(.onboardingGrantMicrophone))
                .accessibilityHint("Request microphone permission")
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.localized(.onboardingAccessibility))
                        .font(.headline)
                    Spacer()
                    if accessibilityGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }

                Button(localization.localized(.onboardingOpenAccessibility)) {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(localization.localized(.onboardingOpenAccessibility))
                .accessibilityHint("Open System Settings to grant accessibility permission")

                Button(localization.localized(.onboardingRecheckAccessibility)) {
                    accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(localization.localized(.onboardingRecheckAccessibility))
                .accessibilityHint("Check if accessibility permission has been granted")
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
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(localization.currentLanguage == code ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundColor(localization.currentLanguage == code ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func applyDefaultLanguageIfNeeded() {
        guard UserDefaults.standard.string(forKey: "ui_language") == nil else { return }
        let localeCode = Locale.current.language.languageCode?.identifier ?? Locale.current.language.languageCode?.identifier ?? "en"
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
            selectedMode = .cloud
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
