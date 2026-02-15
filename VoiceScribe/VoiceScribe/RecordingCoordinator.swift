//
//  RecordingCoordinator.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
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
    private var previewPanel: NSPanel?
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
                debugLog("✅ 麥克風權限已授予")
            } else {
                debugLog("❌ 麥克風權限被拒絕")
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
                debugLog("✅ 通知權限已授予")
            } else {
                debugLog("❌ 通知權限被拒絕")
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
                debugLog("❌ 發送通知失敗：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            debugLog("⌨️ 全域快捷鍵按下（Fn + Space）")
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            debugLog("⌨️ 全域快捷鍵放開")
            self?.stopRecording()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager.startMonitoring()
        }
    }

    private func startRecording() {
        debugLog("🎤 開始錄音...")
        if isSoundFeedbackEnabled() {
            NSSound(named: "Tink")?.play()
        }
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        debugLog("🛑 停止錄音...")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            debugLog("❌ 無法取得錄音檔案")
            appState.updateStatus(.idle)
            return
        }

        debugLog("📁 錄音檔案：\(audioURL.path)")

        let selectedMode = TranscriptionMode(rawValue: UserDefaults.standard.string(forKey: "transcription_mode") ?? "cloud") ?? .cloud
        let selectedLanguage = TranscriptionLanguage(rawValue: UserDefaults.standard.string(forKey: "transcription_language") ?? "auto") ?? .auto
        let languageCode = selectedLanguage.whisperCode

        if selectedMode == .cloud {
            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                showNotification(
                    title: localization.localized(.apiKeyRequiredTitle),
                    body: localization.localized(.apiKeyRequiredBody),
                    isError: true
                )
                appState.updateStatus(.idle)
                hotkeyManager.restartMonitoring()
                audioRecorder.deleteRecording(at: audioURL)
                return
            }
        }

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    debugLog("✅ 轉錄成功：\(transcribedText)")

                    let enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
                    debugLog("🔍 [AI 潤飾] 設定狀態：\(enableAIPolish)")

                    if enableAIPolish {
                        if selectedMode == .local, !NetworkMonitor.shared.isOnline {
                            debugLog("⚠️ [AI 潤飾] 離線模式，使用基本清理")
                            let cleaned = TextCleaner.basicCleanup(transcribedText)
                            self?.processFinalText(cleaned)
                        } else {
                            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                                debugLog("⚠️ [AI 潤飾] 未設定 OpenAI API Key，跳過 AI 潤飾")
                                self?.processFinalText(transcribedText)
                                return
                            }

                            debugLog("🤖 開始 AI 潤飾...")
                            let customPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt")

                            self?.openAIService.polishText(transcribedText, customPrompt: customPrompt) { polishResult in
                                DispatchQueue.main.async {
                                    let finalText: String
                                    switch polishResult {
                                    case .success(let polishedText):
                                        debugLog("✅ AI 潤飾成功：\(polishedText)")
                                        finalText = polishedText
                                    case .failure(let error):
                                        debugLog("❌ AI 潤飾失敗：\(error.localizedDescription)")
                                        debugLog("⚠️ 使用原始轉錄文字")

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
                    debugLog("❌ 轉錄失敗：\(error.localizedDescription)")

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
        panel.title = localization.localized(.downloadingTitle)
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
        let correctedText = TechTermsDictionary.apply(to: text)
        appState.saveTranscription(correctedText)

        if isSoundFeedbackEnabled() {
            NSSound(named: "Pop")?.play()
        }

        let autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")

        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        let shouldAutoPaste = hasLaunchedBefore ? autoPaste : true
        let shouldRestore = true
        let previewEnabled = UserDefaults.standard.bool(forKey: "enable_preview_mode")

        let finalize: () -> Void = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.hotkeyManager.restartMonitoring()
            }
            self?.appState.updateStatus(.idle)
        }

        if previewEnabled {
            showTranscriptionPreview(text: correctedText, restoreClipboard: shouldRestore, finalize: finalize)
            return
        }

        if shouldAutoPaste {
            textInputService.pasteText(correctedText, restoreClipboard: shouldRestore)
        } else {
            showTranscriptionResult(correctedText)
        }

        finalize()
    }

    private func showTranscriptionPreview(text: String, restoreClipboard: Bool, finalize: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.closePreviewPanel()

            let previewView = TranscriptionPreviewView(
                text: text,
                onPaste: { [weak self] editedText in
                    self?.textInputService.pasteText(editedText, restoreClipboard: restoreClipboard)
                    self?.closePreviewPanel()
                    finalize()
                },
                onCancel: { [weak self] in
                    self?.closePreviewPanel()
                    finalize()
                }
            )

            let hostingController = NSHostingController(rootView: previewView)
            let panel = NSPanel(contentViewController: hostingController)
            panel.styleMask = [.titled, .closable]
            panel.title = localization.localized(.transcriptionResultTitle)
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.setContentSize(NSSize(width: 400, height: 200))
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.previewPanel = panel
        }
    }

    private func closePreviewPanel() {
        previewPanel?.close()
        previewPanel = nil
    }

    private func isSoundFeedbackEnabled() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "enable_sound_feedback") == nil {
            return true
        }
        return defaults.bool(forKey: "enable_sound_feedback")
    }

    private func setupAudioRecorderCallbacks() {
        audioRecorder.onRecordingComplete = { [weak self] url in
            guard let url = url else {
                debugLog("❌ 錄音失敗")
                self?.appState.updateStatus(.idle)
                return
            }

            debugLog("✅ 錄音完成：\(url.path)")
        }

        audioRecorder.onError = { error in
            debugLog("❌ 錄音錯誤：\(error.localizedDescription)")
        }
    }

    // MARK: - Result Display

    private func showTranscriptionResult(_ text: String) {
        let alert = NSAlert()
        alert.messageText = localization.localized(.transcriptionResultTitle)
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: localization.localized(.ok))
        alert.runModal()
    }
}
