//
//  OpenAIService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Foundation

enum OpenAIError: Error {
    case noAPIKey
    case networkError(Error)
    case apiError(String)
    case invalidResponse

    var localizedDescription: String {
        let localization = LocalizationHelper.shared
        
        switch self {
        case .noAPIKey:
            return localization.localized(.invalidAPIKeyActionable)
        case .networkError(let error):
            if let urlError = error as? URLError {
                if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                    return localization.localized(.networkErrorActionable)
                } else if urlError.code == .timedOut {
                    return localization.localized(.processingTimeout)
                }
            }
            return localization.localized(.networkErrorActionable)
        case .apiError(let message):
            let lowered = message.lowercased()
            if lowered.contains("api key") || lowered.contains("incorrect api key") || lowered.contains("invalid api key") || lowered.contains("401") || lowered.contains("unauthorized") {
                return localization.localized(.invalidAPIKeyActionable)
            }
            return localization.localized(.apiErrorPrefix) + message
        case .invalidResponse:
            return localization.currentLanguage == "zh" ? "無效的 API 回應" : "Invalid API response"
        }
    }
}

class OpenAIService {
    static let shared = OpenAIService()

    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let keychainHelper = KeychainHelper.shared
    private var currentTask: URLSessionDataTask?

    // 預設 System Prompt
    private let defaultSystemPrompt = """
    You are a voice-to-text post-processor for software developers. Rules:
    1. Remove filler words (um, uh, 唔, 嗯, 那個, 就是, like, you know)
    2. Fix grammar and add proper punctuation
    3. Preserve ALL technical terms exactly: framework names (React, FastAPI, Kubernetes), language names (Python, TypeScript), tools (Docker, Git), and code identifiers (camelCase, snake_case, PascalCase)
    4. Keep mixed-language input as-is — do NOT translate between languages
    5. Keep the original meaning and tone
    6. Output in the same language mix as the input
    """

    private let defaultPromptSummary = "Default: remove filler words, fix grammar, preserve technical terms, keep mixed-language input."





    private init() {}
    
    /// Cancel the current polishing request
    func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
        debugLog("🚫 [OpenAIService] 已取消當前請求")
    }

    // MARK: - Polish Text

    /// 使用 GPT-5-mini 優化文字
    func polishText(_ text: String, customPrompt: String? = nil, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        debugLog("🔍 [OpenAIService] 開始 AI 潤飾")
        debugLog("🔍 [OpenAIService] 輸入文字：\(text)")
        debugLog("🔍 [OpenAIService] 文字長度：\(text.count) 字元")

        // 檢查 API Key
        guard let apiKey = keychainHelper.get(key: "openai_api_key"), !apiKey.isEmpty else {
            debugLog("❌ [OpenAIService] 沒有 API Key")
            completion(.failure(.noAPIKey))
            return
        }

        // 使用自訂 prompt 或預設 prompt
        let trimmedPrompt = customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        let systemPrompt = (trimmedPrompt?.isEmpty == false ? trimmedPrompt : defaultSystemPrompt) ?? defaultSystemPrompt
        debugLog("🔍 [OpenAIService] 使用的 System Prompt：\(systemPrompt.prefix(100))...")

        // 建立請求
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30  // 30 seconds timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 建立請求 body（使用 GPT-5-mini 的參數）
        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "reasoning": [
                "effort": "low"  // 使用 low reasoning effort 來平衡速度和品質
            ],
            "text": [
                "verbosity": "low"  // 使用 low verbosity 來產生簡潔的回應
            ]
        ]

        debugLog("🔍 [OpenAIService] 請求 body 已建立（使用 gpt-5-mini）")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            // Debug: 印出請求內容
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                debugLog("🔍 [OpenAIService] 請求 JSON：\(jsonString)")
            }
        } catch {
            debugLog("❌ [OpenAIService] 建立請求 body 失敗：\(error)")
            completion(.failure(.networkError(error)))
            return
        }

        debugLog("📡 [OpenAIService] 發送請求到 OpenAI API...")

        // 發送請求
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Clear the current task reference
            self?.currentTask = nil
            
            if let error = error {
                // Check if it was cancelled
                if (error as NSError).code == NSURLErrorCancelled {
                    debugLog("🚫 [OpenAIService] 請求已被取消")
                    return
                }
                debugLog("❌ [OpenAIService] 網路錯誤：\(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                debugLog("❌ [OpenAIService] 沒有收到資料")
                completion(.failure(.invalidResponse))
                return
            }

            // Debug: 印出原始回應
            if let responseString = String(data: data, encoding: .utf8) {
                debugLog("🔍 [OpenAIService] API 回應：\(responseString.prefix(500))...")
            }

            // 解析回應
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 檢查是否有錯誤
                    if let errorObj = json["error"] as? [String: Any],
                       let message = errorObj["message"] as? String {
                        debugLog("❌ [OpenAIService] API 錯誤：\(message)")
                        completion(.failure(.apiError(message)))
                        return
                    }

                    // 取得優化後的文字
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        debugLog("✅ [OpenAIService] AI 潤飾結果：\(trimmedContent)")
                        completion(.success(trimmedContent))
                        return
                    }
                }

                debugLog("❌ [OpenAIService] 無法解析回應")
                completion(.failure(.invalidResponse))
            } catch {
                debugLog("❌ [OpenAIService] 解析錯誤：\(error)")
                completion(.failure(.networkError(error)))
            }
        }

        currentTask = task
        task.resume()
    }

    // MARK: - Helper Methods

    /// 取得預設 System Prompt
    func getDefaultSystemPrompt() -> String {
        return defaultSystemPrompt
    }

    /// 取得預設 Prompt 摘要
    func getDefaultPromptSummary() -> String {
        return defaultPromptSummary
    }

}
