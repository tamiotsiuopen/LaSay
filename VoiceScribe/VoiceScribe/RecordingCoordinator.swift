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
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            appState.updateStatus(.idle)
            return
        }

        // Start processing timeout timer (60 seconds)
        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
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

        let selectedMode = TranscriptionMode.fromSaved(UserDefaults.standard.string(forKey: "transcription_mode"))
        let selectedLanguage = TranscriptionLanguage(rawValue: UserDefaults.standard.string(forKey: "transcription_language") ?? "auto") ?? .auto
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

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let rawText):
                    let transcribedText = self.convertToTraditionalChinese(rawText)
                    // Cloud mode: always enable AI Polish (user already has API key)
                    let enableAIPolish = (selectedMode == .cloud) ? true : UserDefaults.standard.bool(forKey: "enable_ai_polish")

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

                            let customPrompt = UserDefaults.standard.string(forKey: "custom_system_prompt")
                            let savedStyle = UserDefaults.standard.string(forKey: "punctuation_style") ?? "fullWidth"
                            let puncStyle = PunctuationStyle(rawValue: savedStyle) ?? .fullWidth

                            self.openAIService.polishText(transcribedText, customPrompt: customPrompt, punctuationStyle: puncStyle) { [weak self] polishResult in
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    
                                    let finalText: String
                                    switch polishResult {
                                    case .success(let polishedText):
                                        finalText = polishedText
                                    case .failure(let error):
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

                case .failure(let error):
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
                let enableAIPolish = UserDefaults.standard.bool(forKey: "enable_ai_polish")
                let techCorrected = enableAIPolish ? text : TechTermsDictionary.apply(to: text)
                let savedStyle = UserDefaults.standard.string(forKey: "punctuation_style") ?? "fullWidth"
                let style = PunctuationStyle(rawValue: savedStyle) ?? .fullWidth
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
