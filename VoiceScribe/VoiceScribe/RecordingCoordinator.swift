//
//  RecordingCoordinator.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Cocoa
import SwiftUI
import UserNotifications
import os.log

final class RecordingCoordinator {
    private let appState: AppState
    private let audioRecorder: AudioRecorder
    private let cloudService: WhisperService
    private let senseVoiceService: SenseVoiceService
    private let openAIService: OpenAIService
    private let textInputService: TextInputService
    private let hotkeyManager: HotkeyManager
    private let localization: LocalizationHelper

    private var processingTimer: Timer?
    
    /// Cancel all ongoing API requests
    func cancelAllRequests() {
        cloudService.cancelCurrentRequest()
        openAIService.cancelCurrentRequest()
    }

    init(
        appState: AppState,
        audioRecorder: AudioRecorder,
        cloudService: WhisperService,
        senseVoiceService: SenseVoiceService,
        openAIService: OpenAIService,
        textInputService: TextInputService,
        hotkeyManager: HotkeyManager,
        localization: LocalizationHelper
    ) {
        self.appState = appState
        self.audioRecorder = audioRecorder
        self.cloudService = cloudService
        self.senseVoiceService = senseVoiceService
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
            if !granted {
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func showNotification(title: String, body: String, isError: Bool = false) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = isError ? .defaultCritical : .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            self?.stopRecording()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager.startMonitoring()
        }
    }

    private func startRecording() {
        AppLogger.recording.info("RecordingCoordinator: recording started")
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        AppLogger.recording.info("RecordingCoordinator: recording stopped")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            AppLogger.recording.error("RecordingCoordinator: no audio URL available after stop")
            appState.updateStatus(.idle)
            return
        }

        // 空錄音保護：檔案小於 1KB 視為錄音太短
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int) ?? 0
        if fileSize < 1024 {
            AppLogger.recording.info("RecordingCoordinator: audio file too small (\(fileSize, privacy: .public) bytes), skipping transcription")
            audioRecorder.deleteRecording(at: audioURL)
            showNotification(title: "錄音太短", body: "請按住 Fn+Space 說話，放開後自動辨識")
            appState.updateStatus(.idle)
            return
        }

        // Start processing timeout timer (60 seconds)
        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            AppLogger.transcription.error("RecordingCoordinator: processing timeout reached")
            DispatchQueue.main.async {
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

        let selectedMode = AppSettings.shared.transcriptionMode
        let selectedLanguage = AppSettings.shared.transcriptionLanguage
        let languageCode = selectedLanguage.languageCode

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

        AppLogger.transcription.info("RecordingCoordinator: starting transcription (mode=\(selectedMode.rawValue, privacy: .public))")

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let rawText):
                    AppLogger.transcription.info("RecordingCoordinator: transcription succeeded")
                    let transcribedText = self.convertToTraditionalChinese(rawText)
                    let enableAIPolish = AppSettings.shared.enableAIPolish

                    // Delete recording immediately — text is already in memory
                    self.audioRecorder.deleteRecording(at: audioURL)

                    if enableAIPolish {
                        if selectedMode == .senseVoice, !NetworkMonitor.shared.isOnline {
                            let cleaned = TextCleaner.basicCleanup(transcribedText)
                            self.processFinalText(cleaned)
                        } else {
                            guard let apiKey = KeychainHelper.shared.get(key: "openai_api_key"), !apiKey.isEmpty else {
                                self.processFinalText(transcribedText)
                                return
                            }

                            AppLogger.transcription.info("RecordingCoordinator: AI Polish started")
                            let customPrompt = AppSettings.shared.customSystemPrompt
                            // Cloud 模式固定全形標點，不額外加指令拖慢 AI Polish
                            let puncStyle: PunctuationStyle = (selectedMode == .cloud) ? .fullWidth : AppSettings.shared.punctuationStyle

                            // Helper to decide if an error is retryable (network/response errors only)
                            func isRetryablePolishError(_ err: OpenAIError) -> Bool {
                                switch err {
                                case .networkError, .invalidResponse: return true
                                default: return false
                                }
                            }

                            self.openAIService.polishText(transcribedText, customPrompt: customPrompt, punctuationStyle: puncStyle) { [weak self] polishResult in
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }

                                    switch polishResult {
                                    case .success(let polishedText):
                                        AppLogger.transcription.info("RecordingCoordinator: AI Polish succeeded")
                                        self.processFinalText(polishedText)

                                    case .failure(let firstError) where isRetryablePolishError(firstError):
                                        // Retry once for transient errors
                                        AppLogger.transcription.info("RecordingCoordinator: AI Polish failed (transient), retrying once")
                                        self.openAIService.polishText(transcribedText, customPrompt: customPrompt, punctuationStyle: puncStyle) { [weak self] retryResult in
                                            DispatchQueue.main.async { [weak self] in
                                                guard let self = self else { return }
                                                let finalText: String
                                                switch retryResult {
                                                case .success(let polishedText):
                                                    AppLogger.transcription.info("RecordingCoordinator: AI Polish retry succeeded")
                                                    finalText = polishedText
                                                case .failure(let retryError):
                                                    AppLogger.transcription.error("RecordingCoordinator: AI Polish retry failed - \(retryError.localizedDescription, privacy: .public)")
                                                    self.showNotification(
                                                        title: self.localization.localized(.aiPolishFailed),
                                                        body: self.localization.localized(.usingOriginalText) + retryError.localizedDescription,
                                                        isError: false
                                                    )
                                                    finalText = transcribedText
                                                }
                                                self.processFinalText(finalText)
                                            }
                                        }

                                    case .failure(let error):
                                        AppLogger.transcription.error("RecordingCoordinator: AI Polish failed - \(error.localizedDescription, privacy: .public)")
                                        self.showNotification(
                                            title: self.localization.localized(.aiPolishFailed),
                                            body: self.localization.localized(.usingOriginalText) + error.localizedDescription,
                                            isError: false
                                        )
                                        self.processFinalText(transcribedText)
                                    }
                                }
                            }
                        }
                    } else {
                        self.processFinalText(transcribedText)
                    }

                case .failure(let error):
                    AppLogger.transcription.error("RecordingCoordinator: transcription failed - \(error.localizedDescription, privacy: .public)")
                    self.processingTimer?.invalidate()
                    self.processingTimer = nil

                    self.showNotification(
                        title: self.localization.localized(.transcriptionFailed),
                        body: error.localizedDescription,
                        isError: true
                    )
                    
                    self.audioRecorder.deleteRecording(at: audioURL)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.hotkeyManager.restartMonitoring()
                    }
                    self.appState.updateStatus(.idle)
                }
            }
        }

        switch selectedMode {
        case .senseVoice:
            senseVoiceService.transcribe(
                audioFileURL: audioURL,
                language: languageCode,
                completion: transcriptionHandler
            )
        case .cloud:
            cloudService.transcribe(audioFileURL: audioURL, language: languageCode, completion: transcriptionHandler)
        }
    }

    // MARK: - Text Processing
    
    private func convertToTraditionalChinese(_ text: String) -> String {
        return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
    }

    private func processFinalText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.processingTimer?.invalidate()
            self.processingTimer = nil
            
            let correctedText: String = {
                // TechTermsDictionary only for offline mode — AI Polish handles this contextually
                let enableAIPolish = AppSettings.shared.enableAIPolish
                let techCorrected = enableAIPolish ? text : TechTermsDictionary.apply(to: text)
                let style = AppSettings.shared.punctuationStyle
                return PunctuationConverter.convert(techCorrected, to: style)
            }()
            self.appState.saveTranscription(correctedText)

            self.textInputService.pasteText(correctedText, restoreClipboard: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.hotkeyManager.restartMonitoring()
            }
            self.appState.updateStatus(.idle)
        }
    }

    private func setupAudioRecorderCallbacks() {
        audioRecorder.onRecordingComplete = { [weak self] url in
            guard let _ = url else {
                self?.appState.updateStatus(.idle)
                return
            }
        }

        audioRecorder.onError = { _ in }
    }

}
