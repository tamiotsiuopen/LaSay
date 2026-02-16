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
    @State private var microphoneGranted: Bool = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted: Bool = HotkeyManager.shared.checkAccessibilityPermission()
    @State private var refreshUI: Bool = false
    @State private var isPulsing: Bool = false
    @State private var permissionTimer: Timer? = nil
    @State private var restartCountdown: Int? = nil
    @State private var restartTimer: Timer? = nil
    @State private var wasAccessibilityGranted: Bool = HotkeyManager.shared.checkAccessibilityPermission()

    private let localization = LocalizationHelper.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let countdown = restartCountdown {
                restartingView(countdown: countdown)
            } else if step == 0 {
                permissionsStep
            } else {
                tryItStep
            }

            Spacer()

            if restartCountdown == nil {
                HStack {
                    if step > 0 {
                        Button(localization.localized(.back)) {
                            step -= 1
                        }
                        .accessibilityLabel(localization.localized(.onboardingBackAccessibility))
                        .accessibilityHint("Go to previous step")
                    }

                    Spacer()

                    if step == 0 {
                        Button(localization.localized(.next)) {
                            stopPermissionPolling()
                            step += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!microphoneGranted || !accessibilityGranted)
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
        }
        .padding(28)
        .frame(width: 460, height: 300)
        .id(refreshUI)
        .onAppear {
            applyDefaultLanguageIfNeeded()
            applyDefaultModeIfNeeded()
        }
    }

    // MARK: - Restarting View

    private func restartingView(countdown: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(localization.currentLanguage == "zh" ? "權限設定完成！" : "Permissions granted!")
                .font(.title)
                .fontWeight(.bold)

            Text(localization.currentLanguage == "zh"
                 ? "即將自動重新啟動 LaSay（\(countdown) 秒）…"
                 : "Restarting LaSay in \(countdown) seconds…")
                .foregroundColor(.secondary)

            Text(localization.currentLanguage == "zh"
                 ? "重啟後即可使用 Fn + Space 語音輸入"
                 : "After restart, use Fn + Space for voice input")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permissions Step

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

                if !microphoneGranted {
                    Button(localization.localized(.onboardingGrantMicrophone)) {
                        AudioRecorder.shared.requestMicrophonePermission { granted in
                            microphoneGranted = granted
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(localization.localized(.onboardingGrantMicrophone))
                    .accessibilityHint("Request microphone permission")
                }
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

                if !accessibilityGranted {
                    Button(localization.localized(.onboardingOpenAccessibility)) {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(localization.localized(.onboardingOpenAccessibility))
                    .accessibilityHint("Open System Settings to grant accessibility permission")
                }
            }
        }
        .onAppear { startPermissionPolling() }
        .onDisappear { stopPermissionPolling() }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        wasAccessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                microphoneGranted = AudioRecorder.shared.checkMicrophonePermission()
                let newAccessibility = HotkeyManager.shared.checkAccessibilityPermission()

                // Detect accessibility just granted → trigger auto-restart
                if !wasAccessibilityGranted && newAccessibility && microphoneGranted {
                    accessibilityGranted = true
                    stopPermissionPolling()
                    startRestartCountdown()
                    return
                }

                wasAccessibilityGranted = newAccessibility
                accessibilityGranted = newAccessibility
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    // MARK: - Auto-Restart

    private func startRestartCountdown() {
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "has_launched_before")

        restartCountdown = 3
        restartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                guard let current = restartCountdown else {
                    timer.invalidate()
                    return
                }
                if current <= 1 {
                    timer.invalidate()
                    restartApp()
                } else {
                    restartCountdown = current - 1
                }
            }
        }
    }

    private func restartApp() {
        guard let bundleURL = Bundle.main.bundleURL as URL? else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Try It Step

    private var tryItStep: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .opacity(isPulsing ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear { isPulsing = true }
            
            Text(localization.localized(.onboardingTryItTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingTryItPrompt))
                .font(.headline)

            Text(localization.localized(.onboardingTryItDescription))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Defaults

    private func applyDefaultLanguageIfNeeded() {
        guard UserDefaults.standard.string(forKey: "ui_language") == nil else { return }
        let localeCode = Locale.current.language.languageCode?.identifier ?? "en"
        let normalized = localeCode.lowercased()
        let defaultLanguage = normalized.hasPrefix("zh") ? "zh" : "en"
        UserDefaults.standard.set(defaultLanguage, forKey: "ui_language")
        refreshUI.toggle()
    }

    private func applyDefaultModeIfNeeded() {
        guard UserDefaults.standard.string(forKey: "transcription_mode") == nil else { return }
        UserDefaults.standard.set("senseVoice", forKey: "transcription_mode")
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
