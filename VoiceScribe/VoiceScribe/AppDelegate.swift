//
//  AppDelegate.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var recordingCoordinator: RecordingCoordinator?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let localization = LocalizationHelper.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(
            appState: AppState.shared,
            hotkeyManager: HotkeyManager.shared,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onShowAbout: { [weak self] in self?.showAbout() },
            onQuit: { [weak self] in self?.quitApp() }
        )
        menuBarManager?.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)

        recordingCoordinator = RecordingCoordinator(
            appState: AppState.shared,
            audioRecorder: AudioRecorder.shared,
            whisperService: WhisperService.shared,
            localWhisperService: LocalWhisperService.shared,
            senseVoiceService: SenseVoiceService.shared,
            openAIService: OpenAIService.shared,
            textInputService: TextInputService.shared,
            hotkeyManager: HotkeyManager.shared,
            localization: localization
        )
        recordingCoordinator?.start()

        // Pre-load local model on launch if user has a local mode selected
        preloadLocalModelIfNeeded()

        checkFirstLaunch()
    }

    @objc func openSettings() {
        // 如果設定視窗已經打開，直接聚焦
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 建立設定視窗
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        // 視窗標題根據介面語言顯示
        window.title = localization.localized(.settingsWindowTitle)
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 480))
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 讓視窗置於最前面
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc func openOnboarding() {
        if let window = onboardingWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: "has_launched_before")
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = localization.localized(.onboardingWindowTitle)
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    @objc func showAbout() {
        // Reuse existing window if already open
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Create AboutView inline
        let aboutView = VStack(spacing: 16) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
            
            Text("LaSay")
                .font(.title)
                .fontWeight(.bold)
            
            Text(localization.currentLanguage == "zh" 
                 ? "版本 \(version) (Build \(build))"
                 : "Version \(version) (Build \(build))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(localization.currentLanguage == "zh"
                 ? "給開發者的語音輸入工具"
                 : "Voice Input for Developers")
                .font(.headline)
                .padding(.top, 4)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.currentLanguage == "zh" ? "功能：" : "Features:")
                    .font(.headline)
                
                if localization.currentLanguage == "zh" {
                    Text("• 本地 + 雲端語音辨識")
                    Text("• AI 文字清理（保留技術術語）")
                    Text("• 全域快捷鍵：Fn + Space")
                    Text("• 任何 app 都能用，包括 Terminal 和 IDE")
                } else {
                    Text("• Local + Cloud speech recognition")
                    Text("• AI text cleanup (preserves technical terms)")
                    Text("• Global Hotkey: Fn + Space")
                    Text("• Works in any app, including Terminal and IDE")
                }
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            Text(localization.currentLanguage == "zh"
                 ? "聯繫：tamio.tsiu@gmail.com"
                 : "Contact: tamio.tsiu@gmail.com")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400, height: 420)

        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = localization.localized(.aboutTitle)
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 420))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        aboutWindow = window
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Model Pre-loading

    private func preloadLocalModelIfNeeded() {
        let mode = TranscriptionMode.fromSaved(UserDefaults.standard.string(forKey: "transcription_mode"))
        switch mode {
        case .whisperLocal:
            if LocalWhisperService.shared.isModelDownloaded {
                LocalWhisperService.shared.preloadModel()
            }
        case .senseVoice:
            if SenseVoiceService.shared.isModelDownloaded {
                SenseVoiceService.shared.preloadModel()
            }
        case .cloud:
            break
        }
    }

    // MARK: - First Launch

    func checkFirstLaunch() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "has_launched_before")
        if !hasLaunched {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.openOnboarding()
            }
        }
    }
}
