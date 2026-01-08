import MagicKit
import SwiftUI

/// Commit 风格选择器
enum CommitStyle: String, CaseIterable {
    case emoji = "Emoji风格"
    case plain = "纯文本风格"
    case lowercase = "纯文本小写"

    var label: String {
        return self.rawValue
    }

    var includeEmoji: Bool {
        switch self {
        case .emoji:
            return true
        case .plain, .lowercase:
            return false
        }
    }

    var isLowercase: Bool {
        switch self {
        case .lowercase:
            return true
        case .emoji, .plain:
            return false
        }
    }
}

struct CommitStylePicker: View {
    @EnvironmentObject var g: DataProvider
    @Binding var selection: CommitStyle

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CommitStyle.allCases, id: \.self) { style in
                Text(style.label)
                    .tag(style as CommitStyle?)
            }
        }
        .frame(width: 120)
        .pickerStyle(.automatic)
        .onChange(of: selection) { _, _ in
            saveCommitStyle()
        }
    }

    private func saveCommitStyle() {
        g.repoManager.stateRepo.setCommitStyle(selection)
    }
}

// MARK: - Preview

#Preview("App-Small Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .hideSidebar()
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
