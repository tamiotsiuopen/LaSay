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
    private var floatingIndicator: FloatingIndicatorController?
    private let localization = LocalizationHelper.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(
            appState: AppState.shared,
            hotkeyManager: HotkeyManager.shared,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onShowAbout: { [weak self] in self?.showAbout() },
            onQuit: { [weak self] in self?.quitApp() },
            onRequestAccessibility: { [weak self] in
                self?.recordingCoordinator?.requestAccessibilityPermission()
            }
        )
        menuBarManager?.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)

        recordingCoordinator = RecordingCoordinator(
            appState: AppState.shared,
            audioRecorder: AudioRecorder.shared,
            whisperService: WhisperService.shared,
            localWhisperService: LocalWhisperService.shared,
            openAIService: OpenAIService.shared,
            textInputService: TextInputService.shared,
            hotkeyManager: HotkeyManager.shared,
            localization: localization
        )
        recordingCoordinator?.start()

        floatingIndicator = FloatingIndicatorController(appState: AppState.shared)

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
        let fittingSize = hostingController.view.fittingSize
        window.setContentSize(NSSize(width: 500, height: fittingSize.height))
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let alert = NSAlert()
        alert.messageText = localization.localized(.aboutTitle)

        let description: String
        if localization.currentLanguage == "zh" {
            description = """
            給開發者的語音輸入工具

            版本：\(version) (Build \(build)) - 測試版

            專為用兩種語言思考的開發者設計。
            口述技術討論、筆記、混語言想法 — LaSay 會保留你的技術術語。

            功能：
            • 本地 + 雲端語音辨識
            • AI 文字清理（保留技術術語）
            • 全域快捷鍵：Fn + Space
            • 任何 app 都能用，包括 Terminal 和 IDE

            聯繫：tamio.tsiu@gmail.com
            """
        } else {
            description = """
            Voice Input for Developers

            Version: \(version) (Build \(build)) - Beta

            Built for developers who think in two languages.
            Dictate code discussions, technical notes, and mixed-language thoughts — LaSay keeps your technical terms intact.

            Features:
            • Local + Cloud speech recognition
            • AI text cleanup (preserves technical terms)
            • Global Hotkey: Fn + Space
            • Works in any app, including Terminal and IDE

            Contact: tamio.tsiu@gmail.com
            """
        }

        alert.informativeText = description
        alert.alertStyle = .informational
        alert.addButton(withTitle: localization.localized(.ok))
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
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
