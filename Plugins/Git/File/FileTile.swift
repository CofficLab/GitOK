import MagicKit
import LibGit2Swift
import SwiftUI

struct FileTile: View {
    var file: GitDiffFile
    var onDiscardChanges: ((GitDiffFile) -> Void)?

    @State var isPresented: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(file.file)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer()

            statusIcon
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 8)
        .cornerRadius(4)
        .contextMenu {
            if let onDiscardChanges = onDiscardChanges {
                Button("Discard Changes") {
                    onDiscardChanges(file)
                }
            }
        }
    }

    private var statusIcon: some View {
        let (icon, color) = iconInfo(for: file.changeType)
        return Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(2)
            .cornerRadius(6)
    }

    private func iconInfo(for change: String) -> (String, Color) {
        let normalizedChange = change.uppercased()
        switch normalizedChange {
        case "M", "MODIFIED":
            return (.iconEditCircle, .orange)
        case "A", "ADDED", "NEW":
            return (.iconPlus, .green)
        case "D", "DELETED":
            return (.iconMinus, .red)
        case "R", "RENAMED":
            return (.iconEditCircle, .blue)
        case "C", "COPIED":
            return (.iconEditCircle, .purple)
        default:
            print("[FileTile] Unknown change type: '\(change)'")
            return (.iconInfo, .gray)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideTabPicker()
            .hideProjectActions()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
