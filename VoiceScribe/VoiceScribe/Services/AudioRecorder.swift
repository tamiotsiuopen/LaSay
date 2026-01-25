//
//  AudioRecorder.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Foundation
import AVFoundation

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

    // MARK: - Recording

    /// 開始錄音
    func startRecording() {
        // 檢查權限
        guard checkMicrophonePermission() else {
            print("❌ 沒有麥克風權限")
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

            print("✅ 開始錄音：\(url.path)")
        } catch {
            print("❌ 錄音失敗：\(error.localizedDescription)")
            onError?(error)
        }
    }

    /// 停止錄音
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            print("⚠️ 沒有正在進行的錄音")
            return
        }

        recorder.stop()
        print("✅ 停止錄音")
    }

    /// 取得最後一次錄音的 URL
    func getLastRecordingURL() -> URL? {
        return recordingURL
    }

    /// 刪除錄音檔案
    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("✅ 刪除錄音檔案：\(url.path)")
        } catch {
            print("❌ 刪除錄音檔案失敗：\(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ 錄音完成：\(recorder.url.path)")
            onRecordingComplete?(recorder.url)
        } else {
            print("❌ 錄音未成功完成")
            onRecordingComplete?(nil)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ 錄音編碼錯誤：\(error.localizedDescription)")
            onError?(error)
        }
    }
}
