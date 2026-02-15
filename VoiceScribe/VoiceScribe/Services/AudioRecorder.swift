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
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugLog("[ERROR] 發送麥克風權限通知失敗：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Recording

    /// 開始錄音
    func startRecording() {
        // 檢查權限
        guard checkMicrophonePermission() else {
            debugLog("[ERROR] 沒有麥克風權限")
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

        // 設定錄音參數（Whisper 相容格式）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,  // Whisper 推薦 16kHz
            AVNumberOfChannelsKey: 1,  // 單聲道
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            debugLog("[OK] 開始錄音：\(url.path)")
        } catch {
            // 使用 defer 確保錯誤時清理臨時檔案
            defer {
                if FileManager.default.fileExists(atPath: url.path) {
                    deleteRecording(at: url)
                }
                recordingURL = nil
            }
            
            debugLog("[ERROR] 錄音失敗：\(error.localizedDescription)")
            onError?(error)
        }
    }

    /// 停止錄音
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            debugLog("[WARN] 沒有正在進行的錄音")
            return
        }

        recorder.stop()
        debugLog("[OK] 停止錄音")
    }

    /// 取得最後一次錄音的 URL
    func getLastRecordingURL() -> URL? {
        return recordingURL
    }

    /// 刪除錄音檔案
    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            debugLog("[OK] 刪除錄音檔案：\(url.path)")
        } catch {
            debugLog("[ERROR] 刪除錄音檔案失敗：\(error.localizedDescription)")
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
        // 使用 defer 確保在所有路徑都清理 URL 引用（但不刪除檔案，因為可能需要轉錄）
        defer {
            // 清理後由呼叫方負責刪除檔案（在轉錄完成後）
        }
        
        if flag {
            debugLog("[OK] 錄音完成：\(recorder.url.path)")
            onRecordingComplete?(recorder.url)
        } else {
            debugLog("[ERROR] 錄音未成功完成")
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
            debugLog("[ERROR] 錄音編碼錯誤：\(error.localizedDescription)")
            onError?(error)
        }
    }
}
