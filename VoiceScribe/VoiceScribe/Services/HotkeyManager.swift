//
//  HotkeyManager.swift
//  VoiceScribe
//
//  Created by Claude on 2026/1/25.
//

import Cocoa
import ApplicationServices

class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // 回調
    var onHotkeyPressed: (() -> Void)?
    var onHotkeyReleased: (() -> Void)?

    // 預設快捷鍵：Fn + Space
    private var modifierFlags: CGEventFlags = [.maskSecondaryFn]
    private var keyCode: CGKeyCode = 49  // Space 鍵

    private init() {}

    // MARK: - Accessibility Permission

    /// 檢查 Accessibility 權限
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 請求 Accessibility 權限
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let result = AXIsProcessTrustedWithOptions(options)
        print("🔍 [HotkeyManager] requestAccessibilityPermission 結果：\(result)")
    }

    /// 顯示權限引導視窗
    func showAccessibilityAlert() {
        let localization = LocalizationHelper.shared

        let alert = NSAlert()
        alert.messageText = localization.localized(.accessibilityPermissionTitle)
        alert.informativeText = localization.localized(.accessibilityPermissionMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: localization.localized(.openSystemSettings))
        alert.addButton(withTitle: localization.localized(.restartLater))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()

            // 啟動背景檢查，監聽權限變化
            startPermissionMonitoring()
        }
    }

    /// 監聽權限變化，授予後自動提示重啟
    private func startPermissionMonitoring() {
        // 每 1 秒檢查一次權限狀態
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.checkAccessibilityPermission() {
                timer.invalidate()  // 停止檢查
                self.showRestartAlert()
            }
        }
    }

    /// 顯示重啟提示
    private func showRestartAlert() {
        let localization = LocalizationHelper.shared

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = localization.localized(.accessibilityGrantedTitle)
            alert.informativeText = localization.localized(.accessibilityGrantedMessage)
            alert.alertStyle = .informational
            alert.addButton(withTitle: localization.localized(.restartNow))
            alert.addButton(withTitle: localization.localized(.restartLater))

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.restartApp()
            }
        }
    }

    /// 重啟 app
    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }

    /// 打開系統設定的輔助使用頁面
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Hotkey Management

    /// 啟動全域快捷鍵監聽
    func startMonitoring() {
        print("🔍 [HotkeyManager] 開始設定全域快捷鍵監聽...")

        // 檢查權限（使用 prompt 選項強制請求）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options)
        print("🔍 [HotkeyManager] Accessibility 權限狀態：\(hasPermission)")

        guard hasPermission else {
            print("⚠️ [HotkeyManager] 沒有 Accessibility 權限")
            print("💡 [HotkeyManager] 系統應該會顯示權限請求對話框")
            print("💡 [HotkeyManager] 請在系統設定中允許 LaSay 並重新啟動 app")
            return
        }

        // 如果已經在監聽，先停止
        if eventTap != nil {
            print("🔍 [HotkeyManager] 停止現有監聽...")
            stopMonitoring()
        }

        // 創建事件監聽器
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        print("🔍 [HotkeyManager] 嘗試創建事件監聽器（event mask: \(eventMask)）...")

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ [HotkeyManager] 無法創建事件監聽器（CGEvent.tapCreate 返回 nil）")
            print("❌ [HotkeyManager] 這表示 Accessibility 權限未正確授予或未生效")
            print("💡 [HotkeyManager] 請嘗試以下步驟：")
            print("   1. 完全退出 LaSay")
            print("   2. 系統設定 → 隱私權與安全性 → 輔助使用")
            print("   3. 移除 LaSay（點擊 - 按鈕）")
            print("   4. 重新啟動 LaSay，會再次請求權限")
            return
        }

        print("✅ [HotkeyManager] 事件監聽器創建成功")
        self.eventTap = eventTap

        // 創建 run loop source
        print("🔍 [HotkeyManager] 創建 run loop source...")
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        print("✅ [HotkeyManager] Run loop source 已添加")

        // 啟用事件監聽
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("✅ [HotkeyManager] 事件監聽已啟用")

        print("✅ 全域快捷鍵監聽已啟動（Fn + Space）")
        print("💡 [HotkeyManager] 請按住 Fn + Space 測試")
    }

    /// 停止監聽
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
            print("✅ [HotkeyManager] 全域快捷鍵監聽已停止")
        }
    }

    /// 重新啟動監聽（用於恢復）
    func restartMonitoring() {
        print("🔄 [HotkeyManager] 重新啟動事件監聽...")
        stopMonitoring()

        // 短暫延遲後重新啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }

    // MARK: - Event Handling

    private var isHotkeyPressed = false

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 處理 flags changed（修飾鍵變化）
        if type == .flagsChanged {
            return Unmanaged.passRetained(event)
        }

        // 獲取按鍵資訊
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // 檢查是否是 Space 鍵
        let isTargetKey = keyCode == Int64(self.keyCode)

        // 檢查是否按住 Fn 鍵
        let hasModifiers = flags.contains(.maskSecondaryFn)

        // 優先處理 keyUp：只要是 Space 鍵且之前按下過，就觸發放開（不管 Fn 鍵是否還按著）
        if type == .keyUp && isTargetKey && isHotkeyPressed {
            print("✅ [HotkeyManager] 檢測到快捷鍵放開")
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyReleased?()
            }
            return nil  // 消費此事件
        }

        // 處理 keyDown：檢測到 Space 鍵 + Fn 鍵的組合
        if isTargetKey && hasModifiers {
            if type == .keyDown && !isHotkeyPressed {
                print("✅ [HotkeyManager] 檢測到快捷鍵按下")
                isHotkeyPressed = true
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkeyPressed?()
                }
            }
            // 消費所有符合條件的事件
            return nil
        }

        // 如果正在錄音中，消費所有 Space 鍵事件（防止傳遞到應用產生嘟嘟聲）
        if isHotkeyPressed && isTargetKey {
            return nil
        }

        // 不是我們的快捷鍵，讓事件繼續傳遞
        return Unmanaged.passRetained(event)
    }

    // MARK: - Custom Hotkey (預留給階段 6 後期實作)

    /// 設定自訂快捷鍵
    func setCustomHotkey(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        self.keyCode = keyCode
        self.modifierFlags = modifiers

        // 重新啟動監聽
        if eventTap != nil {
            stopMonitoring()
            startMonitoring()
        }
    }

    /// 取得當前快捷鍵描述
    func getCurrentHotkeyDescription() -> String {
        return "Fn + Space"  // 目前固定為此組合
    }
}
