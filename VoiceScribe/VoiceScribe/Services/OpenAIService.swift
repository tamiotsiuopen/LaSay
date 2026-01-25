//
//  OpenAIService.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Foundation

enum OpenAIError: Error {
    case noAPIKey
    case networkError(Error)
    case apiError(String)
    case invalidResponse

    var localizedDescription: String {
        switch self {
        case .noAPIKey:
            return "未設定 OpenAI API Key"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .apiError(let message):
            return "API 錯誤：\(message)"
        case .invalidResponse:
            return "無效的 API 回應"
        }
    }
}

class OpenAIService {
    static let shared = OpenAIService()

    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let keychainHelper = KeychainHelper.shared

    // 預設 System Prompt
    private let defaultSystemPrompt = """
    你是一個專業的文字潤飾助手。你的任務是優化語音轉錄的文字，使其更加通順流暢。

    請執行以下優化：
    1. 移除口語贅字（例如：「呃」、「那個」、「就是」、「然後」等）
    2. 修正文法錯誤和標點符號
    3. 調整句子結構，使其更加通順
    4. 保持原意和語氣，不要添加或刪除實質內容

    直接輸出優化後的文字，不要添加任何說明或註解。
    """

    private init() {}

    // MARK: - Polish Text

    /// 使用 GPT-5-mini 優化文字
    func polishText(_ text: String, customPrompt: String? = nil, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        // 檢查 API Key
        guard let apiKey = keychainHelper.get(key: "openai_api_key"), !apiKey.isEmpty else {
            completion(.failure(.noAPIKey))
            return
        }

        // 使用自訂 prompt 或預設 prompt
        let systemPrompt = customPrompt?.isEmpty == false ? customPrompt! : defaultSystemPrompt

        // 建立請求
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 建立請求 body（使用 GPT-5-mini 的新參數）
        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "reasoning_effort": "low",  // 優先速度
            "verbosity": "low"  // 精簡回應
            // gpt-5-mini 不支援自訂 temperature，只能使用預設值 1
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

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

                    // 取得優化後的文字
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        completion(.success(trimmedContent))
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

    // MARK: - Helper Methods

    /// 取得預設 System Prompt
    func getDefaultSystemPrompt() -> String {
        return defaultSystemPrompt
    }
}
