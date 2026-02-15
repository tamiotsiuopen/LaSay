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
            debugLog("❌ KeychainHelper: 無法將字串轉換為 Data")
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
            debugLog("✅ KeychainHelper: 更新成功 - \(key)")
            return true
        } else if updateStatus == errSecItemNotFound {
            // 項目不存在，新增
            var newItem = query
            newItem[kSecValueData as String] = data

            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            if addStatus == errSecSuccess {
                debugLog("✅ KeychainHelper: 新增成功 - \(key)")
                return true
            } else {
                debugLog("❌ KeychainHelper: 新增失敗 - \(key), status: \(addStatus)")
                return false
            }
        } else {
            debugLog("❌ KeychainHelper: 更新失敗 - \(key), status: \(updateStatus)")
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
                debugLog("✅ KeychainHelper: 讀取成功 - \(key)")
                return value
            } else {
                debugLog("❌ KeychainHelper: 無法將 Data 轉換為字串 - \(key)")
                return nil
            }
        } else if status == errSecItemNotFound {
            debugLog("⚠️ KeychainHelper: 項目不存在 - \(key)")
            return nil
        } else {
            debugLog("❌ KeychainHelper: 讀取失敗 - \(key), status: \(status)")
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
            debugLog("✅ KeychainHelper: 刪除成功 - \(key)")
            return true
        } else if status == errSecItemNotFound {
            debugLog("⚠️ KeychainHelper: 項目不存在（刪除時） - \(key)")
            return true // 不存在也算成功
        } else {
            debugLog("❌ KeychainHelper: 刪除失敗 - \(key), status: \(status)")
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

        debugLog("🔄 KeychainHelper: 開始遷移...")

        // 嘗試遷移已知的 key（目前只有 openai_api_key）
        let keysToMigrate = ["openai_api_key"]

        for key in keysToMigrate {
            let legacyKey = "\(legacyKeyPrefix)_\(key)"
            
            if let encoded = UserDefaults.standard.string(forKey: legacyKey),
               let data = Data(base64Encoded: encoded),
               let value = String(data: data, encoding: .utf8) {
                
                // 遷移到 Keychain
                if save(key: key, value: value) {
                    debugLog("✅ KeychainHelper: 遷移成功 - \(key)")
                    // 刪除舊的 UserDefaults 值
                    UserDefaults.standard.removeObject(forKey: legacyKey)
                } else {
                    debugLog("❌ KeychainHelper: 遷移失敗 - \(key)")
                }
            }
        }

        // 標記遷移完成
        UserDefaults.standard.set(true, forKey: migrationKey)
        debugLog("✅ KeychainHelper: 遷移完成")
    }
}
