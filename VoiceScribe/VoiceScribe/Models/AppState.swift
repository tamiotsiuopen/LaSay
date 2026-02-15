//
//  AppState.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Foundation
import SwiftUI
import Combine

// 應用程式狀態枚舉
enum AppStatus {
    case idle        // 待機
    case recording   // 錄音中
    case processing  // 處理中（轉錄/AI 潤飾）

    var iconName: String {
        switch self {
        case .idle:
            return "mic"  // 空心麥克風
        case .recording:
            return "mic.fill"  // 實心麥克風
        case .processing:
            return "waveform.circle.fill"  // 實心波形圓圈
        }
    }

    var iconColor: NSColor {
        switch self {
        case .idle:
            return .systemGray
        case .recording:
            return .systemRed
        case .processing:
            return .systemBlue
        }
    }
}

// 應用程式狀態管理器（ObservableObject）
class AppState: ObservableObject {
    @Published var status: AppStatus = .idle
    @Published var lastTranscription: String = ""

    // 單例模式
    static let shared = AppState()

    private init() {}

    // 更新狀態
    func updateStatus(_ newStatus: AppStatus) {
        DispatchQueue.main.async {
            self.status = newStatus
        }
    }

    // 儲存最後一次轉錄結果
    func saveTranscription(_ text: String) {
        DispatchQueue.main.async {
            self.lastTranscription = text
        }
    }
}
