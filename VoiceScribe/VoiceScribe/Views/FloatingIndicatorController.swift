//
//  FloatingIndicatorController.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Cocoa
import SwiftUI
import Combine

final class FloatingIndicatorController {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<FloatingIndicatorView>?
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        observeStateChanges()
    }

    private func observeStateChanges() {
        appState.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateIndicator(for: status)
            }
            .store(in: &cancellables)
    }

    private func updateIndicator(for status: AppStatus) {
        switch status {
        case .idle:
            hideIndicator()
        case .recording, .processing:
            showIndicator(for: status)
        }
    }

    private func showIndicator(for status: AppStatus) {
        if let existingPanel = panel {
            // 更新現有面板
            if let hostingController = hostingController {
                hostingController.rootView = FloatingIndicatorView(status: status)
            }
            return
        }

        // 創建新面板
        let indicatorView = FloatingIndicatorView(status: status)
        let hostingController = NSHostingController(rootView: indicatorView)
        self.hostingController = hostingController

        let panel = NSPanel(contentViewController: hostingController)
        panel.styleMask = [.borderless, .nonactivatingPanel]
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.ignoresMouseEvents = false

        // 定位到螢幕右上角
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelSize = hostingController.view.fittingSize
            let xPos = screenFrame.maxX - panelSize.width - 20
            let yPos = screenFrame.maxY - panelSize.height - 20
            panel.setFrame(NSRect(origin: CGPoint(x: xPos, y: yPos), size: panelSize), display: true)
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func hideIndicator() {
        panel?.orderOut(nil)
        panel = nil
        hostingController = nil
    }

    deinit {
        hideIndicator()
    }
}
