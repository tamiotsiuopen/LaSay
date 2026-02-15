//
//  MenuBarManager.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import Cocoa
import Combine
import QuartzCore

final class MenuBarManager: NSObject {
    private let appState: AppState
    private let hotkeyManager: HotkeyManager
    private let onOpenSettings: () -> Void
    private let onShowAbout: () -> Void
    private let onQuit: () -> Void
    private let onRequestAccessibility: () -> Void

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    init(
        appState: AppState,
        hotkeyManager: HotkeyManager,
        onOpenSettings: @escaping () -> Void,
        onShowAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onRequestAccessibility: @escaping () -> Void
    ) {
        self.appState = appState
        self.hotkeyManager = hotkeyManager
        self.onOpenSettings = onOpenSettings
        self.onShowAbout = onShowAbout
        self.onQuit = onQuit
        self.onRequestAccessibility = onRequestAccessibility
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateMenuBarIcon()
        }

        setupMenu()
        observeStateChanges()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: NSNotification.Name("RefreshMenu"),
            object: nil
        )
    }

    @objc private func handleSettingsChanged() {
        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Menu bar 固定使用英文
        // 狀態顯示（動態更新）
        let statusText: String
        switch appState.status {
        case .idle:
            statusText = "Status: Idle"
        case .recording:
            statusText = "Status: Recording..."
        case .processing:
            statusText = "Status: Processing..."
        }
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        let currentMode = TranscriptionMode(rawValue: UserDefaults.standard.string(forKey: "transcription_mode") ?? "cloud") ?? .cloud
        let modeItem = NSMenuItem(title: "Mode: \(currentMode.displayName)", action: nil, keyEquivalent: "")
        modeItem.isEnabled = false
        menu.addItem(modeItem)

        let currentTemplate = PolishTemplate(rawValue: UserDefaults.standard.string(forKey: "polish_template") ?? "general") ?? .general
        let templateItem = NSMenuItem(title: "Template: \(currentTemplate.displayName)", action: nil, keyEquivalent: "")
        templateItem.isEnabled = false
        menu.addItem(templateItem)

        menu.addItem(NSMenuItem.separator())

        // 快捷鍵提示
        let hotkeyHint: String
        if appState.status == .idle {
            hotkeyHint = "💡 Hold Fn+Space to start recording"
        } else if appState.status == .recording {
            hotkeyHint = "🎤 Recording... (Release Fn+Space to stop)"
        } else {
            hotkeyHint = "⏳ Processing..."
        }
        let hintItem = NSMenuItem(title: hotkeyHint, action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        menu.addItem(hintItem)

        let modeSwitchItem = NSMenuItem(title: "Switch Mode", action: nil, keyEquivalent: "")
        let modeMenu = NSMenu()
        for mode in TranscriptionMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(changeMode(_:)), keyEquivalent: "")
            item.representedObject = mode.rawValue
            item.state = mode == currentMode ? .on : .off
            item.target = self
            modeMenu.addItem(item)
        }
        modeSwitchItem.submenu = modeMenu
        menu.addItem(modeSwitchItem)

        let templateSwitchItem = NSMenuItem(title: "Switch Template", action: nil, keyEquivalent: "")
        let templateMenu = NSMenu()
        for template in PolishTemplate.allCases {
            let item = NSMenuItem(title: template.displayName, action: #selector(changeTemplate(_:)), keyEquivalent: "")
            item.representedObject = template.rawValue
            item.state = template == currentTemplate ? .on : .off
            item.target = self
            templateMenu.addItem(item)
        }
        templateSwitchItem.submenu = templateMenu
        menu.addItem(templateSwitchItem)

        menu.addItem(NSMenuItem.separator())

        // 最後轉錄結果（如果有）
        if !appState.lastTranscription.isEmpty {
            let transcriptionText = appState.lastTranscription.count > 30
                ? String(appState.lastTranscription.prefix(30)) + "..."
                : appState.lastTranscription
            let transcriptionItem = NSMenuItem(title: "Last Transcription: \(transcriptionText)", action: nil, keyEquivalent: "")
            transcriptionItem.isEnabled = false
            menu.addItem(transcriptionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // API Key 狀態檢查
        let apiKey = KeychainHelper.shared.get(key: "openai_api_key")
        if apiKey == nil || apiKey?.isEmpty == true {
            let apiKeyItem = NSMenuItem(title: "⚠️ Please set OpenAI API Key first", action: #selector(openSettings), keyEquivalent: "")
            apiKeyItem.target = self
            menu.addItem(apiKeyItem)
            menu.addItem(NSMenuItem.separator())
        }

        // 權限狀態檢查
        if !hotkeyManager.checkAccessibilityPermission() {
            let permissionItem = NSMenuItem(title: "⚠️ Accessibility permission required", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
            permissionItem.target = self
            menu.addItem(permissionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Menu bar 選單固定使用英文
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "About LaSay", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit LaSay", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func observeStateChanges() {
        appState.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
                self?.setupMenu()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let status = appState.status
        let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "LaSay")
        image?.isTemplate = false

        button.image = image

        if let imageView = button.subviews.first as? NSImageView {
            imageView.contentTintColor = status.iconColor
            imageView.wantsLayer = true
            imageView.layer?.removeAllAnimations()

            switch status {
            case .idle:
                imageView.alphaValue = 1.0
                imageView.layer?.transform = CATransform3DIdentity

            case .recording:
                let pulseAnimation = CABasicAnimation(keyPath: "opacity")
                pulseAnimation.duration = 0.8
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 0.3
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                imageView.layer?.add(pulseAnimation, forKey: "pulse")

            case .processing:
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotationAnimation.duration = 2.0
                rotationAnimation.fromValue = 0
                rotationAnimation.toValue = Double.pi * 2
                rotationAnimation.repeatCount = .infinity
                rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
                imageView.layer?.add(rotationAnimation, forKey: "rotation")
            }
        }
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func showAbout() {
        onShowAbout()
    }

    @objc private func quitApp() {
        onQuit()
    }

    @objc private func requestAccessibilityPermission() {
        onRequestAccessibility()
    }

    @objc private func changeMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else { return }
        UserDefaults.standard.set(rawValue, forKey: "transcription_mode")
        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
        setupMenu()
    }

    @objc private func changeTemplate(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else { return }
        UserDefaults.standard.set(rawValue, forKey: "polish_template")
        NotificationCenter.default.post(name: NSNotification.Name("RefreshMenu"), object: nil)
        setupMenu()
    }
}
