//
//  AppDelegate.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var recordingCoordinator: RecordingCoordinator?
    private var settingsWindow: NSWindow?
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

        recordingCoordinator = RecordingCoordinator(
            appState: AppState.shared,
            audioRecorder: AudioRecorder.shared,
            whisperService: WhisperService.shared,
            openAIService: OpenAIService.shared,
            textInputService: TextInputService.shared,
            hotkeyManager: HotkeyManager.shared,
            localization: localization
        )
        recordingCoordinator?.start()

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
        let windowTitle = localization.currentLanguage == "en" ? "LaSay Settings" : "LaSay 設定"
        window.title = windowTitle
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 讓視窗置於最前面
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let alert = NSAlert()
        alert.messageText = "LaSay"

        // 根據介面語言顯示不同內容
        let isEnglish = localization.currentLanguage == "en"

        if isEnglish {
            alert.informativeText = """
            macOS System-wide Voice Input Tool

            Version: \(version) (Build \(build)) - Beta

            Features:
            • Whisper Speech Transcription
            • GPT-5-mini AI Text Polishing
            • Global Hotkey: Fn + Space

            Privacy:
            • No data collection
            • All processing via OpenAI API
            • API Key stored securely locally

            Contact:
            • Slack: Tamio Tsiu
            • Email: tamio.tsiu@gmail.com
            • Email: tamio.tsiu@opennet.tw
            """
        } else {
            alert.informativeText = """
            macOS 系統級語音輸入工具

            版本：\(version) (Build \(build)) - 測試版

            功能：
            • Whisper 語音轉錄
            • GPT-5-mini AI 文字潤飾
            • 全域快捷鍵：Fn + Space

            隱私：
            • 不收集任何使用資料
            • 所有處理透過 OpenAI API
            • API Key 安全儲存於本機

            聯繫方式：
            • Slack: Tamio Tsiu
            • Email: tamio.tsiu@gmail.com
            • Email: tamio.tsiu@opennet.tw
            """
        }

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
            // 延遲 1 秒後自動打開設定
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.openSettings()
            }
        }
    }
}
