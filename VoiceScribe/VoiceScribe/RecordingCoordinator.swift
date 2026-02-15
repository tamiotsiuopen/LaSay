//
//  RecordingCoordinator.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import Cocoa
import SwiftUI
import UserNotifications

final class RecordingCoordinator {
    private let appState: AppState
    private let audioRecorder: AudioRecorder
    private let whisperService: WhisperService
    private let localWhisperService: LocalWhisperService
    private let openAIService: OpenAIService
    private let textInputService: TextInputService
    private let hotkeyManager: HotkeyManager
    private let localization: LocalizationHelper

    private var downloadPanel: NSPanel?
    private let downloadProgressModel = DownloadProgressViewModel()

    init(
        appState: AppState,
        audioRecorder: AudioRecorder,
        whisperService: WhisperService,
        localWhisperService: LocalWhisperService,
        openAIService: OpenAIService,
        textInputService: TextInputService,
        hotkeyManager: HotkeyManager,
        localization: LocalizationHelper
    ) {
        self.appState = appState
        self.audioRecorder = audioRecorder
        self.whisperService = whisperService
        self.localWhisperService = localWhisperService
        self.openAIService = openAIService
        self.textInputService = textInputService
        self.hotkeyManager = hotkeyManager
        self.localization = localization
    }

    func start() {
        requestNotificationPermission()
        requestMicrophonePermission()
        setupAudioRecorderCallbacks()
        setupGlobalHotkey()
    }

    func requestAccessibilityPermission() {
        hotkeyManager.showAccessibilityAlert()
    }

    // MARK: - Microphone Permission

    private func requestMicrophonePermission() {
        audioRecorder.requestMicrophonePermission { [weak self] granted in
            if granted {
                print("✅ 麥克風權限已授予")
            } else {
                print("❌ 麥克風權限被拒絕")
                self?.showMicrophonePermissionAlert()
            }
        }
    }

    private func showMicrophonePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = localization.localized(.microphonePermissionTitle)
        alert.informativeText = localization.localized(.microphonePermissionMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: localization.localized(.openSystemSettings))
        alert.addButton(withTitle: localization.localized(.cancel))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ 通知權限已授予")
            } else {
                print("❌ 通知權限被拒絕")
            }
        }
    }

    private func showNotification(title: String, body: String, isError: Bool = false) {
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

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            print("⌨️ 全域快捷鍵按下（Fn + Space）")
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            print("⌨️ 全域快捷鍵放開")
            self?.stopRecording()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager.startMonitoring()
        }
    }

    private func startRecording() {
        print("🎤 開始錄音...")
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        print("🛑 停止錄音...")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            print("❌ 無法取得錄音檔案")
            appState.updateStatus(.idle)
            return
        }

        print("📁 錄音檔案：\(audioURL.path)")

        let selectedMode = TranscriptionMode(rawValue: UserDefaults.standard.string(forKey: "transcription_mode") ?? "cloud") ?? .cloud
        let selectedLanguage = TranscriptionLanguage(rawValue: UserDefaults.standard.string(forKey: "transcription_language") ?? "auto") ?? .auto
        let languageCode = selectedLanguage.whisperCode

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    print("✅ 轉錄成功：\(transcribedText)")

                    let enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
                    print("🔍 [AI 潤飾] 設定狀態：\(enableAIPolish)")

                    if enableAIPolish {
                        if selectedMode == .local, !NetworkMonitor.isOnline() {
                            print("⚠️ [AI 潤飾] 離線模式，使用基本清理")
                            let cleaned = TextCleaner.basicCleanup(transcribedText)
                            self?.processFinalText(cleaned)
                        } else {
                            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                                print("⚠️ [AI 潤飾] 未設定 OpenAI API Key，跳過 AI 潤飾")
                                self?.processFinalText(transcribedText)
                                return
                            }

                            print("🤖 開始 AI 潤飾...")
                            let customPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt")
                            let template = PolishTemplate(rawValue: UserDefaults.standard.string(forKey: "polish_template") ?? "general") ?? .general
                            let prompt = self?.openAIService.resolvePrompt(customPrompt: customPrompt, template: template)

                            self?.openAIService.polishText(transcribedText, customPrompt: prompt) { polishResult in
                                DispatchQueue.main.async {
                                    let finalText: String
                                    switch polishResult {
                                    case .success(let polishedText):
                                        print("✅ AI 潤飾成功：\(polishedText)")
                                        finalText = polishedText
                                    case .failure(let error):
                                        print("❌ AI 潤飾失敗：\(error.localizedDescription)")
                                        print("⚠️ 使用原始轉錄文字")

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
                        }
                    } else {
                        self?.processFinalText(transcribedText)
                    }

                    self?.audioRecorder.deleteRecording(at: audioURL)

                case .failure(let error):
                    print("❌ 轉錄失敗：\(error.localizedDescription)")

                    self?.showNotification(
                        title: self?.localization.localized(.transcriptionFailed) ?? "Transcription Failed",
                        body: error.localizedDescription,
                        isError: true
                    )

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.hotkeyManager.restartMonitoring()
                    }
                    self?.appState.updateStatus(.idle)
                }
            }
        }

        switch selectedMode {
        case .local:
            localWhisperService.transcribe(
                audioFileURL: audioURL,
                language: languageCode,
                progressHandler: { [weak self] progress in
                    self?.handleDownloadProgress(progress)
                },
                completion: transcriptionHandler
            )
        case .cloud:
            whisperService.transcribe(audioFileURL: audioURL, language: languageCode, completion: transcriptionHandler)
        }
    }

    // MARK: - Download Progress

    private func handleDownloadProgress(_ progress: LocalWhisperService.DownloadProgress) {
        let titleKey: LocalizationKey = (progress.kind == .model) ? .downloadingModel : .downloadingBinary
        downloadProgressModel.title = localization.localized(titleKey)
        downloadProgressModel.progress = progress.fraction
        downloadProgressModel.sizeText = formatByteCount(progress.bytesExpected)

        showDownloadPanelIfNeeded()

        if progress.isCompleted, progress.kind == .model {
            closeDownloadPanelAfterDelay()
        }
    }

    private func formatByteCount(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func showDownloadPanelIfNeeded() {
        guard downloadPanel == nil else { return }

        let hostingController = NSHostingController(rootView: DownloadProgressView(model: downloadProgressModel))
        let panel = NSPanel(contentViewController: hostingController)
        panel.styleMask = [.titled, .closable]
        panel.title = localization.currentLanguage == "zh" ? "下載中" : "Downloading"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        downloadPanel = panel
    }

    private func closeDownloadPanelAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.downloadPanel?.close()
            self?.downloadPanel = nil
        }
    }

    // MARK: - Text Processing

    private func processFinalText(_ text: String) {
        appState.saveTranscription(text)

        let autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")
        let restoreClipboard = UserDefaults.standard.bool(forKey: "restore_clipboard")

        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        let shouldAutoPaste = hasLaunchedBefore ? autoPaste : true
        let shouldRestore = hasLaunchedBefore ? restoreClipboard : true

        if shouldAutoPaste {
            textInputService.pasteText(text, restoreClipboard: shouldRestore)
        } else {
            showTranscriptionResult(text)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hotkeyManager.restartMonitoring()
        }

        appState.updateStatus(.idle)
    }

    private func setupAudioRecorderCallbacks() {
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

    private func showTranscriptionResult(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "轉錄結果"
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}
