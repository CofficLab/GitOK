//
//  ResponseBodyView.swift
//  GitOK
//
//  Created by Angel on 2024/12/13.
//

import SwiftUI


// 响应体视图
struct ResponseBodyView: View {
    let response: APIResponse?
    @State private var viewMode: ViewMode = .pretty

    enum ViewMode {
        case pretty, raw, preview, visualize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("View Mode", selection: $viewMode) {
                    Text("Pretty").tag(ViewMode.pretty)
                    Text("Raw").tag(ViewMode.raw)
                    Text("Preview").tag(ViewMode.preview)
                    Text("Visualize").tag(ViewMode.visualize)
                }
                .pickerStyle(.segmented)

                Spacer()

                if let mimeType = response?.mimeType {
                    Text(mimeType)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            if let body = response?.body {
                Text(body)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
}
