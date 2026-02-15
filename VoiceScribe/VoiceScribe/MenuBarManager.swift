//
//  MenuBarManager.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
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
            button.setAccessibilityLabel(LocalizationHelper.shared.localized(.menuBarStatusAccessibility))
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
        let localization = LocalizationHelper.shared

        // 狀態顯示
        let statusText: String
        switch appState.status {
        case .idle:
            statusText = localization.localized(.status) + localization.localized(.idle)
        case .recording:
            statusText = localization.localized(.status) + localization.localized(.recording)
        case .processing:
            statusText = localization.localized(.status) + localization.localized(.processing)
        }
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 模式選擇
        let currentMode = TranscriptionMode(rawValue: UserDefaults.standard.string(forKey: "transcription_mode") ?? "cloud") ?? .cloud
        for mode in TranscriptionMode.allCases {
            let title = localization.localized(.modeLabel) + mode.localizedDisplayName
            let item = NSMenuItem(title: title, action: #selector(changeMode(_:)), keyEquivalent: "")
            item.representedObject = mode.rawValue
            item.state = mode == currentMode ? .on : .off
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: localization.localized(.settingsMenu), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: localization.localized(.about), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: localization.localized(.quit), action: #selector(quitApp), keyEquivalent: "q")
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
        let localization = LocalizationHelper.shared
        let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "LaSay")
        image?.isTemplate = false

        button.image = image

        // Update accessibility label and post announcement
        let statusText: String
        switch status {
        case .idle:
            statusText = localization.localized(.idle)
        case .recording:
            statusText = localization.localized(.recording)
        case .processing:
            statusText = localization.localized(.processing)
        }
        
        button.setAccessibilityLabel("\(localization.localized(.menuBarStatusAccessibility)) - \(statusText)")
        
        // Post accessibility announcement for state changes
        let announcement = "\(localization.localized(.menuBarStatusAccessibility)) \(statusText)"
        NSAccessibility.post(element: button, notification: .announcementRequested, userInfo: [
            .announcement: announcement,
            .priority: NSAccessibilityPriorityLevel.high.rawValue
        ])

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

}
