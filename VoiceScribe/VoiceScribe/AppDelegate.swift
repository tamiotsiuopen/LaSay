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

        // 請求麥克風權限
        requestMicrophonePermission()

        // 設定錄音回調
        setupAudioRecorderCallbacks()

        // 設定全域快捷鍵（階段 6）
        setupGlobalHotkey()
    }

    @objc func togglePopover() {
        // 暫時顯示選單而不是 popover
        // 之後會改成顯示狀態視窗
    }

    func setupMenu() {
        let menu = NSMenu()

        // 狀態顯示（動態更新）
        let statusMenuItem = NSMenuItem(title: "狀態：\(appState.status.displayText)", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 快捷鍵提示
        let hotkeyHint: String
        if appState.status == .idle {
            hotkeyHint = "💡 按住 Fn+Space 開始錄音"
        } else if appState.status == .recording {
            hotkeyHint = "🎤 錄音中...（放開 Fn+Space 停止）"
        } else {
            hotkeyHint = "⏳ 處理中..."
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
            let transcriptionItem = NSMenuItem(title: "最後轉錄：\(transcriptionText)", action: nil, keyEquivalent: "")
            transcriptionItem.isEnabled = false
            menu.addItem(transcriptionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // 權限狀態檢查
        if !hotkeyManager.checkAccessibilityPermission() {
            let permissionItem = NSMenuItem(title: "⚠️ 需要授予輔助使用權限", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
            menu.addItem(permissionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // 設定選項
        menu.addItem(NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ","))

        // 關於
        menu.addItem(NSMenuItem(title: "關於 VoiceScribe", action: #selector(showAbout), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // 結束
        menu.addItem(NSMenuItem(title: "結束 VoiceScribe", action: #selector(quitApp), keyEquivalent: "q"))

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
        window.title = "VoiceScribe 設定"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 讓視窗置於最前面
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "VoiceScribe"
        alert.informativeText = "語音輸入工具\n版本 1.0.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
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
        let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "VoiceScribe")
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
        alert.messageText = "需要麥克風權限"
        alert.informativeText = "VoiceScribe 需要麥克風權限才能錄音。請在系統設定中允許麥克風存取。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打開系統設定")
        alert.addButton(withTitle: "取消")

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

        // 取得語言設定
        let language = UserDefaults.standard.string(forKey: "transcription_language") ?? "zh"

        // 調用 Whisper API
        whisperService.transcribe(audioFileURL: audioURL, language: language) { [weak self] result in
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
                    self?.showError(error.localizedDescription)

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

