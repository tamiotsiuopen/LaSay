//
//  DebugLog.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

func debugLog(_ message: String) {
    #if DEBUG
    debugLog(message)
    #endif
}
