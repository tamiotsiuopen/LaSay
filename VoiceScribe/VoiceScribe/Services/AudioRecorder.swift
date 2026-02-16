//
//  AudioRecorder.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Foundation
import AVFoundation
import UserNotifications

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    // 完成回調
    var onRecordingComplete: ((URL?) -> Void)?
    var onError: ((Error) -> Void)?

    // 單例模式
    static let shared = AudioRecorder()

    private override init() {
        super.init()
    }

    // MARK: - Permission

    /// 請求麥克風權限
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// 檢查麥克風權限狀態
    func checkMicrophonePermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .authorized
    }

    /// 顯示麥克風權限被拒絕的通知
    private func showMicrophonePermissionDeniedNotification() {
        let localization = LocalizationHelper.shared
        let content = UNMutableNotificationContent()
        content.title = localization.localized(.microphonePermissionTitle)
        content.body = localization.localized(.microphonePermissionDenied)
        content.sound = .defaultCritical

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Recording

    /// 開始錄音
    func startRecording() {
        // 檢查權限
        guard checkMicrophonePermission() else {
            showMicrophonePermissionDeniedNotification()
            return
        }

        // 如果已經在錄音，先停止
        if audioRecorder?.isRecording == true {
            stopRecording()
        }

        // 創建臨時檔案 URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDirectory.appendingPathComponent(fileName)

        guard let url = recordingURL else { return }

        // 設定錄音參數（16kHz 單聲道，語音辨識標準格式）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,  // 單聲道
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

        } catch {
            // 使用 defer 確保錯誤時清理臨時檔案
            defer {
                if FileManager.default.fileExists(atPath: url.path) {
                    deleteRecording(at: url)
                }
                recordingURL = nil
            }
            
            onError?(error)
        }
    }

    /// 停止錄音
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return
        }

        recorder.stop()
    }

    /// 取得最後一次錄音的 URL
    func getLastRecordingURL() -> URL? {
        return recordingURL
    }

    /// 刪除錄音檔案
    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
        }
    }
    
    /// 清理當前錄音（如果存在）
    func cleanupCurrentRecording() {
        if let url = recordingURL {
            deleteRecording(at: url)
            recordingURL = nil
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            onRecordingComplete?(recorder.url)
        } else {
            // 錄音失敗，立即清理檔案
            deleteRecording(at: recorder.url)
            recordingURL = nil
            onRecordingComplete?(nil)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        // 使用 defer 確保錯誤時清理臨時檔案
        defer {
            if let url = recordingURL {
                deleteRecording(at: url)
                recordingURL = nil
            }
        }
        
        if let error = error {
            onError?(error)
        }
    }
}
