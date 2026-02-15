//
//  KeychainHelper.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//
//  使用 macOS Keychain 進行安全儲存

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {
        // 執行一次性遷移
        migrateFromUserDefaults()
    }

    private let serviceName = "com.tamio.LaSay"
    private let legacyKeyPrefix = "com.tamio.LaSay.openai_api_key"

    // MARK: - Public API

    /// 儲存值到 Keychain
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        // 嘗試更新現有項目
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return true
        } else if updateStatus == errSecItemNotFound {
            // 項目不存在，新增
            var newItem = query
            newItem[kSecValueData as String] = data

            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            if addStatus == errSecSuccess {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    /// 從 Keychain 讀取值
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            if let value = String(data: data, encoding: .utf8) {
                return value
            } else {
                return nil
            }
        } else if status == errSecItemNotFound {
            return nil
        } else {
            return nil
        }
    }

    /// 從 Keychain 刪除值
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            return true
        } else if status == errSecItemNotFound {
            return true // 不存在也算成功
        } else {
            return false
        }
    }

    // MARK: - Migration

    /// 從舊的 UserDefaults Base64 遷移到 Keychain
    private func migrateFromUserDefaults() {
        let migrationKey = "keychain_migration_completed"
        
        // 檢查是否已經遷移過
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }


        // 嘗試遷移已知的 key（目前只有 openai_api_key）
        let keysToMigrate = ["openai_api_key"]

        for key in keysToMigrate {
            let legacyKey = "\(legacyKeyPrefix)_\(key)"
            
            if let encoded = UserDefaults.standard.string(forKey: legacyKey),
               let data = Data(base64Encoded: encoded),
               let value = String(data: data, encoding: .utf8) {
                
                // 遷移到 Keychain
                if save(key: key, value: value) {
                    // 刪除舊的 UserDefaults 值
                    UserDefaults.standard.removeObject(forKey: legacyKey)
                } else {
                }
            }
        }

        // 標記遷移完成
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
