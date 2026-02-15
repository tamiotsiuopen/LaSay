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
    private var processingTimer: Timer?
    
    /// Cancel all ongoing API requests
    func cancelAllRequests() {
        whisperService.cancelCurrentRequest()
        openAIService.cancelCurrentRequest()
        debugLog("[CANCEL] [RecordingCoordinator] 已取消所有進行中的請求")
    }

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
                debugLog("[OK] 麥克風權限已授予")
            } else {
                debugLog("[ERROR] 麥克風權限被拒絕")
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
                debugLog("[OK] 通知權限已授予")
            } else {
                debugLog("[ERROR] 通知權限被拒絕")
            }
        }
    }

    private func showNotification(title: String, body: String, isError: Bool = false) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = isError ? .defaultCritical : .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugLog("[ERROR] 發送通知失敗：\(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            debugLog("[KEY] 全域快捷鍵按下（Fn + Space）")
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            debugLog("[KEY] 全域快捷鍵放開")
            self?.stopRecording()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager.startMonitoring()
        }
    }

    private func startRecording() {
        debugLog("[REC] 開始錄音...")
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        debugLog("[STOP] 停止錄音...")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            debugLog("[ERROR] 無法取得錄音檔案")
            appState.updateStatus(.idle)
            return
        }

        debugLog("[FILE] 錄音檔案：\(audioURL.path)")
        
        // Start processing timeout timer (60 seconds)
        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                debugLog("[TIMEOUT] 處理逾時（60秒）")
                self.showNotification(
                    title: self.localization.localized(.transcriptionFailed),
                    body: self.localization.localized(.processingTimeout),
                    isError: true
                )
                self.appState.updateStatus(.idle)
                self.hotkeyManager.restartMonitoring()
                self.audioRecorder.deleteRecording(at: audioURL)
            }
        }

        let selectedMode = TranscriptionMode(rawValue: UserDefaults.standard.string(forKey: "transcription_mode") ?? "cloud") ?? .cloud
        let selectedLanguage = TranscriptionLanguage(rawValue: UserDefaults.standard.string(forKey: "transcription_language") ?? "auto") ?? .auto
        let languageCode = selectedLanguage.whisperCode

        if selectedMode == .cloud {
            // Check internet connection before proceeding
            if !NetworkMonitor.shared.isOnline {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showNotification(
                        title: self.localization.localized(.noNetworkConnection),
                        body: self.localization.localized(.offlineCloudModeError),
                        isError: true
                    )
                    self.appState.updateStatus(.idle)
                    self.hotkeyManager.restartMonitoring()
                    self.audioRecorder.deleteRecording(at: audioURL)
                }
                return
            }
            
            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                    self.showNotification(
                        title: self.localization.localized(.apiKeyRequiredTitle),
                        body: self.localization.localized(.apiKeyRequiredBody),
                        isError: true
                    )
                    self.appState.updateStatus(.idle)
                    self.hotkeyManager.restartMonitoring()
                    self.audioRecorder.deleteRecording(at: audioURL)
                }
                return
            }
        }

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let rawText):
                    // Convert Simplified Chinese → Traditional Chinese
                    let transcribedText = self.convertToTraditionalChinese(rawText)
                    debugLog("[OK] 轉錄成功：\(transcribedText)")

                    let enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
                    debugLog("[DEBUG] [AI 潤飾] 設定狀態：\(enableAIPolish)")

                    if enableAIPolish {
                        if selectedMode == .local, !NetworkMonitor.shared.isOnline {
                            debugLog("[WARN] [AI 潤飾] 離線模式，使用基本清理")
                            let cleaned = TextCleaner.basicCleanup(transcribedText)
                            self.processFinalText(cleaned)
                        } else {
                            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                                debugLog("[WARN] [AI 潤飾] 未設定 OpenAI API Key，跳過 AI 潤飾")
                                self.processFinalText(transcribedText)
                                return
                            }

                            debugLog("[AI] 開始 AI 潤飾...")
                            let customPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt")

                            self.openAIService.polishText(transcribedText, customPrompt: customPrompt) { [weak self] polishResult in
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    
                                    let finalText: String
                                    switch polishResult {
                                    case .success(let polishedText):
                                        debugLog("[OK] AI 潤飾成功：\(polishedText)")
                                        finalText = polishedText
                                    case .failure(let error):
                                        debugLog("[ERROR] AI 潤飾失敗：\(error.localizedDescription)")
                                        debugLog("[WARN] 使用原始轉錄文字")

                                        self.showNotification(
                                            title: self.localization.localized(.aiPolishFailed),
                                            body: self.localization.localized(.usingOriginalText) + error.localizedDescription,
                                            isError: false
                                        )

                                        finalText = transcribedText
                                    }

                                    self.processFinalText(finalText)
                                }
                            }
                        }
                    } else {
                        self.processFinalText(transcribedText)
                    }

                    self.audioRecorder.deleteRecording(at: audioURL)

                case .failure(let error):
                    debugLog("[ERROR] 轉錄失敗：\(error.localizedDescription)")

                    // Cancel processing timeout timer
                    self.processingTimer?.invalidate()
                    self.processingTimer = nil

                    self.showNotification(
                        title: self.localization.localized(.transcriptionFailed),
                        body: error.localizedDescription,
                        isError: true
                    )

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.hotkeyManager.restartMonitoring()
                    }
                    self.appState.updateStatus(.idle)
                }
            }
        }

        debugLog("[DEBUG] [RecordingCoordinator] Mode: \(selectedMode.rawValue), Language: \(languageCode ?? "auto")")
        
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let titleKey: LocalizationKey = (progress.kind == .model) ? .downloadingModel : .downloadingBinary
            self.downloadProgressModel.title = self.localization.localized(titleKey)
            self.downloadProgressModel.progress = progress.fraction
            self.downloadProgressModel.sizeText = self.formatByteCount(progress.bytesExpected)

            self.showDownloadPanelIfNeeded()

            if progress.isCompleted, progress.kind == .model {
                self.closeDownloadPanelAfterDelay()
            }
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
    
    /// Convert Simplified Chinese to Traditional Chinese using ICU transform
    private func convertToTraditionalChinese(_ text: String) -> String {
        return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
    }

    private func processFinalText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel processing timeout timer
            self.processingTimer?.invalidate()
            self.processingTimer = nil
            
            let correctedText = TechTermsDictionary.apply(to: text)
            self.appState.saveTranscription(correctedText)

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
                self.showTranscriptionPreview(text: correctedText, restoreClipboard: shouldRestore, finalize: finalize)
                return
            }

            if shouldAutoPaste {
                self.textInputService.pasteText(correctedText, restoreClipboard: shouldRestore)
                
                // Show completion notification with text preview
                let previewText = correctedText.count > 50 
                    ? String(correctedText.prefix(50)) + "..." 
                    : correctedText
                let notificationTitle = self.localization.localized(.pastedToCursor)
                self.showNotification(
                    title: notificationTitle,
                    body: previewText
                )
            } else {
                self.showTranscriptionResult(correctedText)
            }

            finalize()
        }
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

    private func setupAudioRecorderCallbacks() {
        audioRecorder.onRecordingComplete = { [weak self] url in
            guard let url = url else {
                debugLog("[ERROR] 錄音失敗")
                self?.appState.updateStatus(.idle)
                return
            }

            debugLog("[OK] 錄音完成：\(url.path)")
        }

        audioRecorder.onError = { error in
            debugLog("[ERROR] 錄音錯誤：\(error.localizedDescription)")
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
