//
//  NetworkMonitor.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private(set) var isOnline: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}
