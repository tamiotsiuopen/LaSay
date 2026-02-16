//
//  HotkeyManager.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import ApplicationServices

class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionCheckTimer: Timer?
    
    // Thread-safe state access
    private let stateQueue = DispatchQueue(label: "com.lasay.hotkeymanager.state")
    private var _isHotkeyPressed = false
    private var isHotkeyPressed: Bool {
        get { stateQueue.sync { _isHotkeyPressed } }
        set { stateQueue.sync { _isHotkeyPressed = newValue } }
    }

    // 回調
    var onHotkeyPressed: (() -> Void)?
    var onHotkeyReleased: (() -> Void)?

    // 預設快捷鍵：Fn + Space
    private var keyCode: CGKeyCode = 49  // Space 鍵

    private init() {}
    
    deinit {
        stopMonitoring()
    }

    // MARK: - Accessibility Permission

    /// 檢查 Accessibility 權限
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 請求 Accessibility 權限
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
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
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.checkAccessibilityPermission() {
                timer.invalidate()  // 停止檢查
                self.permissionCheckTimer = nil
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

        // 檢查權限（使用 prompt 選項強制請求）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options)

        guard hasPermission else {
            return
        }

        // 如果已經在監聽，先停止
        if eventTap != nil {
            stopMonitoring()
        }

        // 創建事件監聽器
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

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
            return
        }

        self.eventTap = eventTap

        // 創建 run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // 啟用事件監聽
        CGEvent.tapEnable(tap: eventTap, enable: true)

    }

    /// 停止監聽
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
        
        // Invalidate permission check timer
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }

    /// 重新啟動監聽（用於恢復）
    func restartMonitoring() {
        stopMonitoring()

        // 短暫延遲後重新啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }

    // MARK: - Event Handling

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
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyReleased?()
            }
            return nil  // 消費此事件
        }

        // 處理 keyDown：檢測到 Space 鍵 + Fn 鍵的組合
        if isTargetKey && hasModifiers {
            if type == .keyDown && !isHotkeyPressed {
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

}
