//
//  TranscriptionPreviewView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI

struct TranscriptionPreviewView: View {
    @State private var editableText: String
    let onPaste: (String) -> Void
    let onCancel: () -> Void

    private let localization = LocalizationHelper.shared

    init(text: String, onPaste: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _editableText = State(initialValue: text)
        self.onPaste = onPaste
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $editableText)
                .border(Color.secondary.opacity(0.3))
                .accessibilityLabel(localization.localized(.transcriptionPreviewAccessibility))
                .accessibilityValue(editableText)
                .accessibilityHint("Edit transcribed text before pasting")

            HStack {
                Spacer()

                Button(localization.localized(.cancel)) {
                    onCancel()
                }
                .accessibilityLabel(localization.localized(.cancelButtonAccessibility))
                .accessibilityHint("Cancel without pasting")

                Button(localization.localized(.paste)) {
                    onPaste(editableText)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel(localization.localized(.pasteButtonAccessibility))
                .accessibilityHint("Paste edited text to cursor position")
            }
        }
        .padding(16)
        .frame(width: 400, height: 200)
    }
}

#Preview {
    TranscriptionPreviewView(text: "Preview text", onPaste: { _ in }, onCancel: {})
}
