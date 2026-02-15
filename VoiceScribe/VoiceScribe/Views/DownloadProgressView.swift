//
//  DownloadProgressView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI
import Combine

final class DownloadProgressViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var progress: Double = 0
    @Published var sizeText: String = ""

    var displayTitle: String {
        if sizeText.isEmpty {
            return title + "..."
        }
        return "\(title) (\(sizeText))..."
    }
}

struct DownloadProgressView: View {
    @ObservedObject var model: DownloadProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.displayTitle)
                .font(.headline)

            ProgressView(value: model.progress)
                .progressViewStyle(.linear)
        }
        .padding(20)
        .frame(width: 320)
    }
}

#Preview {
    let model = DownloadProgressViewModel()
    model.title = "正在下載語音模型"
    model.sizeText = "142MB"
    model.progress = 0.45
    return DownloadProgressView(model: model)
}
