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

        let description = String(format: localization.localized(.aboutDescription), version, build)
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
