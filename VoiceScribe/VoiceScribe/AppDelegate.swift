//
//  AppDelegate.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Cocoa
import SwiftUI
import Combine
import QuartzCore
import AVFoundation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var appState = AppState.shared
    var cancellables = Set<AnyCancellable>()
    var audioRecorder = AudioRecorder.shared
    var whisperService = WhisperService.shared
    var openAIService = OpenAIService.shared
    var textInputService = TextInputService.shared
    var hotkeyManager = HotkeyManager.shared
    var localEventMonitor: Any?
    var settingsWindow: NSWindow?
    var localization = LocalizationHelper.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 創建 menu bar 圖示
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // 使用 SF Symbol 作為圖示
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
        }

        // 設定選單
        setupMenu()

        // 監聽狀態變化
        observeStateChanges()

        // 監聽設定變化（用於刷新 menu）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: NSNotification.Name("RefreshMenu"),
            object: nil
        )

        // 請求通知權限
        requestNotificationPermission()

        // 請求麥克風權限
        requestMicrophonePermission()

        // 設定錄音回調
        setupAudioRecorderCallbacks()

        // 設定全域快捷鍵（階段 6）
        setupGlobalHotkey()

        // 首次啟動引導
        checkFirstLaunch()
    }

    @objc func handleSettingsChanged() {
        // 重新設定選單
        setupMenu()
    }

    @objc func togglePopover() {
        // 暫時顯示選單而不是 popover
        // 之後會改成顯示狀態視窗
    }

    func setupMenu() {
        let menu = NSMenu()

        // Menu bar 固定使用英文
        // 狀態顯示（動態更新）
        let statusText: String
        switch appState.status {
        case .idle:
            statusText = "Status: Idle"
        case .recording:
            statusText = "Status: Recording..."
        case .processing:
            statusText = "Status: Processing..."
        }
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 快捷鍵提示
        let hotkeyHint: String
        if appState.status == .idle {
            hotkeyHint = "💡 Hold Fn+Space to start recording"
        } else if appState.status == .recording {
            hotkeyHint = "🎤 Recording... (Release Fn+Space to stop)"
        } else {
            hotkeyHint = "⏳ Processing..."
        }
        let hintItem = NSMenuItem(title: hotkeyHint, action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        menu.addItem(hintItem)

        menu.addItem(NSMenuItem.separator())

        // 最後轉錄結果（如果有）
        if !appState.lastTranscription.isEmpty {
            let transcriptionText = appState.lastTranscription.count > 30
                ? String(appState.lastTranscription.prefix(30)) + "..."
                : appState.lastTranscription
            let transcriptionItem = NSMenuItem(title: "Last Transcription: \(transcriptionText)", action: nil, keyEquivalent: "")
            transcriptionItem.isEnabled = false
            menu.addItem(transcriptionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // API Key 狀態檢查
        let apiKey = KeychainHelper.shared.get(key: "openai_api_key")
        if apiKey == nil || apiKey?.isEmpty == true {
            let apiKeyItem = NSMenuItem(title: "⚠️ Please set OpenAI API Key first", action: #selector(openSettings), keyEquivalent: "")
            menu.addItem(apiKeyItem)
            menu.addItem(NSMenuItem.separator())
        }

        // 權限狀態檢查
        if !hotkeyManager.checkAccessibilityPermission() {
            let permissionItem = NSMenuItem(title: "⚠️ Accessibility permission required", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
            menu.addItem(permissionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Menu bar 選單固定使用英文
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem(title: "About LaSay", action: #selector(showAbout), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit LaSay", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
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

    // MARK: - State Management

    func observeStateChanges() {
        // 監聽狀態變化，更新 UI
        appState.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
                self?.setupMenu()  // 重新設定選單以更新狀態文字
            }
            .store(in: &cancellables)
    }

    func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let status = appState.status
        let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "LaSay")
        image?.isTemplate = false  // 使用彩色圖示

        button.image = image

        // 設定圖示顏色
        if let imageView = button.subviews.first as? NSImageView {
            imageView.contentTintColor = status.iconColor

            // 確保 imageView 有 layer（用於動畫）
            imageView.wantsLayer = true

            // 移除所有現有動畫
            imageView.layer?.removeAllAnimations()

            // 根據狀態添加動畫
            switch status {
            case .idle:
                // 待機狀態：無動畫
                imageView.alphaValue = 1.0
                imageView.layer?.transform = CATransform3DIdentity

            case .recording:
                // 錄音中：閃爍動畫
                let pulseAnimation = CABasicAnimation(keyPath: "opacity")
                pulseAnimation.duration = 0.8
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 0.3
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                imageView.layer?.add(pulseAnimation, forKey: "pulse")

            case .processing:
                // 處理中：旋轉動畫
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotationAnimation.duration = 2.0
                rotationAnimation.fromValue = 0
                rotationAnimation.toValue = Double.pi * 2
                rotationAnimation.repeatCount = .infinity
                rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
                imageView.layer?.add(rotationAnimation, forKey: "rotation")
            }
        }
    }

    // MARK: - Testing Methods (暫時用於測試狀態切換)

    @objc func testRecording() {
        appState.updateStatus(.recording)
        // 3 秒後切換到處理中
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.appState.updateStatus(.processing)
            // 再 2 秒後回到待機
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.appState.updateStatus(.idle)
            }
        }
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() {
        audioRecorder.requestMicrophonePermission { [weak self] granted in
            if granted {
                print("✅ 麥克風權限已授予")
            } else {
                print("❌ 麥克風權限被拒絕")
                self?.showMicrophonePermissionAlert()
            }
        }
    }

    func showMicrophonePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = localization.localized(.microphonePermissionTitle)
        alert.informativeText = localization.localized(.microphonePermissionMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: localization.localized(.openSystemSettings))
        alert.addButton(withTitle: localization.localized(.cancel))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打開系統設定
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc func requestAccessibilityPermission() {
        hotkeyManager.showAccessibilityAlert()
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ 通知權限已授予")
            } else {
                print("❌ 通知權限被拒絕")
            }
        }
    }

    func showNotification(title: String, body: String, isError: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isError ? .defaultCritical : .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 發送通知失敗：\(error.localizedDescription)")
            }
        }
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

    // MARK: - Global Hotkey (階段 6)

    func setupGlobalHotkey() {
        // 設定快捷鍵回調
        hotkeyManager.onHotkeyPressed = { [weak self] in
            print("⌨️ 全域快捷鍵按下（Fn + Space）")
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            print("⌨️ 全域快捷鍵放開")
            self?.stopRecording()
        }

        // 延遲啟動監聽，確保 app 完全啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager.startMonitoring()
        }
    }

    @objc func startRecording() {
        print("🎤 開始錄音...")
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    @objc func stopRecording() {
        print("🛑 停止錄音...")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        // 取得錄音檔案並調用 Whisper API
        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            print("❌ 無法取得錄音檔案")
            appState.updateStatus(.idle)
            return
        }

        print("📁 錄音檔案：\(audioURL.path)")

        // 調用 Whisper API（自動辨識語言）
        whisperService.transcribe(audioFileURL: audioURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    print("✅ 轉錄成功：\(transcribedText)")

                    // 檢查是否啟用 AI 潤飾
                    let enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
                    print("🔍 [AI 潤飾] 設定狀態：\(enableAIPolish)")

                    if enableAIPolish {
                        // 檢查是否有 API Key
                        guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                            print("⚠️ [AI 潤飾] 未設定 OpenAI API Key，跳過 AI 潤飾")
                            self?.processFinalText(transcribedText)
                            return
                        }

                        // 調用 AI 潤飾
                        print("🤖 開始 AI 潤飾...")
                        let customPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt")

                        self?.openAIService.polishText(transcribedText, customPrompt: customPrompt) { polishResult in
                            DispatchQueue.main.async {
                                let finalText: String
                                switch polishResult {
                                case .success(let polishedText):
                                    print("✅ AI 潤飾成功：\(polishedText)")
                                    finalText = polishedText
                                case .failure(let error):
                                    print("❌ AI 潤飾失敗：\(error.localizedDescription)")
                                    print("⚠️ 使用原始轉錄文字")

                                    // 顯示錯誤通知（但不阻斷流程）
                                    self?.showNotification(
                                        title: self?.localization.localized(.aiPolishFailed) ?? "AI Polishing Failed",
                                        body: (self?.localization.localized(.usingOriginalText) ?? "Using original text: ") + error.localizedDescription,
                                        isError: false
                                    )

                                    finalText = transcribedText
                                }

                                self?.processFinalText(finalText)
                            }
                        }
                    } else {
                        // 不使用 AI 潤飾，直接使用轉錄文字
                        self?.processFinalText(transcribedText)
                    }

                    // 刪除錄音檔案
                    self?.audioRecorder.deleteRecording(at: audioURL)

                case .failure(let error):
                    print("❌ 轉錄失敗：\(error.localizedDescription)")

                    // 顯示錯誤通知
                    self?.showNotification(
                        title: self?.localization.localized(.transcriptionFailed) ?? "Transcription Failed",
                        body: error.localizedDescription,
                        isError: true
                    )

                    // 即使失敗也重新啟動監聽
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.hotkeyManager.restartMonitoring()
                    }
                    self?.appState.updateStatus(.idle)
                }
            }
        }
    }

    // MARK: - Text Processing

    func processFinalText(_ text: String) {
        self.appState.saveTranscription(text)

        // 檢查是否啟用自動貼上
        let autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")
        let restoreClipboard = UserDefaults.standard.bool(forKey: "restore_clipboard")

        // 如果是第一次運行，預設啟用自動貼上
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        let shouldAutoPaste = hasLaunchedBefore ? autoPaste : true
        let shouldRestore = hasLaunchedBefore ? restoreClipboard : true

        if shouldAutoPaste {
            // 自動貼上
            self.textInputService.pasteText(text, restoreClipboard: shouldRestore)
        } else {
            // 不自動貼上，顯示結果
            self.showTranscriptionResult(text)
        }

        // 延遲後重新啟動事件監聽（防止被自動貼上干擾）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hotkeyManager.restartMonitoring()
        }

        self.appState.updateStatus(.idle)
    }

    func setupAudioRecorderCallbacks() {
        audioRecorder.onRecordingComplete = { [weak self] url in
            guard let url = url else {
                print("❌ 錄音失敗")
                self?.appState.updateStatus(.idle)
                return
            }

            print("✅ 錄音完成：\(url.path)")
        }

        audioRecorder.onError = { error in
            print("❌ 錄音錯誤：\(error.localizedDescription)")
        }
    }

    // MARK: - Result Display

    func showTranscriptionResult(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "轉錄結果"
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }

    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "錯誤"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}

