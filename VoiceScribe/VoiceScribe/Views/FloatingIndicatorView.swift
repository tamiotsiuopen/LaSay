//
//  FloatingIndicatorView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI
import Combine

struct FloatingIndicatorView: View {
    let status: AppStatus
    private let localization = LocalizationHelper.shared
    
    @State private var elapsedSeconds: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
                .foregroundColor(iconColor)

            Text(statusTextWithTimer)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localization.localized(.floatingIndicatorAccessibility))
        .accessibilityValue(statusTextWithTimer)
        .onReceive(timer) { _ in
            if status == .recording {
                elapsedSeconds += 1
            }
        }
        .onChange(of: status) { newStatus in
            if newStatus != .recording {
                elapsedSeconds = 0
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .idle:
            EmptyView()
        case .recording:
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .modifier(PulseAnimation())
        case .processing:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .tint(.blue)
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .processing:
            return .blue
        }
    }

    private var statusText: String {
        switch status {
        case .idle:
            return localization.localized(.idle)
        case .recording:
            return localization.localized(.recording)
        case .processing:
            return localization.localized(.processing)
        }
    }
    
    private var statusTextWithTimer: String {
        if status == .recording {
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            let timeString = String(format: "%02d:%02d", minutes, seconds)
            return "\(statusText) \(timeString)"
        } else {
            return statusText
        }
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingIndicatorView(status: .recording)
        FloatingIndicatorView(status: .processing)
    }
    .padding()
}
