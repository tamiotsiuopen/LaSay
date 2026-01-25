//
//  VoiceScribeApp.swift
//  VoiceScribe
//
//  Created by tamiotsiu on 2026/1/25.
//

import SwiftUI

@main
struct VoiceScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu Bar App 不需要視窗
        Settings {
            EmptyView()
        }
    }
}
