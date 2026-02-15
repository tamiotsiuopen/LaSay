//
//  FloatingIndicatorView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI

struct FloatingIndicatorView: View {
    let status: AppStatus
    private let localization = LocalizationHelper.shared

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
                .foregroundColor(iconColor)

            Text(statusText)
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
        .accessibilityValue(statusText)
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
