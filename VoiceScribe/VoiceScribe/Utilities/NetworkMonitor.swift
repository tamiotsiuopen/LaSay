//
//  NetworkMonitor.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import Foundation
import Network

final class NetworkMonitor {
    static func isOnline(timeout: TimeInterval = 0.3) -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        let semaphore = DispatchSemaphore(value: 0)
        var isOnline = true

        monitor.pathUpdateHandler = { path in
            isOnline = path.status == .satisfied
            semaphore.signal()
            monitor.cancel()
        }

        monitor.start(queue: queue)

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            monitor.cancel()
            return true
        }

        return isOnline
    }
}
