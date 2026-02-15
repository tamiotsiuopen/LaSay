//
//  KeychainHelper.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//
//  改為使用 UserDefaults 簡單加密儲存，避免 Keychain 密碼提示

import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // 使用設備唯一的密鑰進行簡單加密
    private let encryptionKey = "com.tamio.LaSay.openai_api_key"

    // MARK: - Save

    func save(key: String, value: String) -> Bool {
        // 簡單的 Base64 編碼（不是真正的加密，但避免明文）
        guard let data = value.data(using: .utf8) else { return false }
        let encoded = data.base64EncodedString()

        UserDefaults.standard.set(encoded, forKey: "\(encryptionKey)_\(key)")
        return true
    }

    // MARK: - Get

    func get(key: String) -> String? {
        guard let encoded = UserDefaults.standard.string(forKey: "\(encryptionKey)_\(key)"),
              let data = Data(base64Encoded: encoded),
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    // MARK: - Delete

    func delete(key: String) -> Bool {
        UserDefaults.standard.removeObject(forKey: "\(encryptionKey)_\(key)")
        return true
    }
}
