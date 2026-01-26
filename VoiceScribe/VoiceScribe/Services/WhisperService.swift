//
//  WhisperService.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Foundation

enum WhisperError: Error {
    case noAPIKey
    case invalidAudioFile
    case networkError(Error)
    case apiError(String)
    case invalidResponse

    var localizedDescription: String {
        switch self {
        case .noAPIKey:
            return "未設定 OpenAI API Key"
        case .invalidAudioFile:
            return "無效的音訊檔案"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .apiError(let message):
            return "API 錯誤：\(message)"
        case .invalidResponse:
            return "無效的 API 回應"
        }
    }
}

class WhisperService {
    static let shared = WhisperService()

    private let apiURL = "https://api.openai.com/v1/audio/transcriptions"
    private let keychainHelper = KeychainHelper.shared

    private init() {}

    // MARK: - Transcribe

    /// 轉錄音訊檔案，自動辨識語言
    /// - Parameters:
    ///   - audioFileURL: 音訊檔案 URL
    ///   - language: 可選的語言代碼（留空則自動辨識）
    ///   - completion: 完成回調
    func transcribe(audioFileURL: URL, language: String? = nil, completion: @escaping (Result<String, WhisperError>) -> Void) {
        // 檢查 API Key
        guard let apiKey = keychainHelper.get(key: "openai_api_key"), !apiKey.isEmpty else {
            completion(.failure(.noAPIKey))
            return
        }

        // 檢查檔案是否存在
        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            completion(.failure(.invalidAudioFile))
            return
        }

        // 建立 multipart/form-data 請求
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 建立 body
        var body = Data()

        // 添加 model 參數
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // 如果指定語言，添加 language 參數（否則自動辨識）
        if let language = language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // 添加音訊檔案
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)

        if let audioData = try? Data(contentsOf: audioFileURL) {
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        } else {
            completion(.failure(.invalidAudioFile))
            return
        }

        // 結束 boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 發送請求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            // 解析回應
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 檢查是否有錯誤
                    if let errorObj = json["error"] as? [String: Any],
                       let message = errorObj["message"] as? String {
                        completion(.failure(.apiError(message)))
                        return
                    }

                    // 取得轉錄文字
                    if let text = json["text"] as? String {
                        completion(.success(text))
                        return
                    }
                }

                completion(.failure(.invalidResponse))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }

        task.resume()
    }
}
