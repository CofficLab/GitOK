//
//  ConsoleView.swift
//  GitOK
//
//  Created by Angel on 2024/12/13.
//

import SwiftUI

// Console 视图
struct ConsoleView: View {
    let logs: [APIResponse.LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(logs, id: \.timestamp) { log in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(logLevelColor(log.level))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.message)
                            .textSelection(.enabled)
                        Text(log.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Divider()
            }
        }
    }

    private func logLevelColor(_ level: APIResponse.LogEntry.LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        case .debug: return .gray
        }
    }
}
