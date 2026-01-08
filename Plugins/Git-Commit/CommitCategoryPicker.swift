import SwiftUI
import MagicKit

/// Commit 类别选择器
struct CommitCategoryPicker: View {
    @Binding var selection: CommitCategory
    var commitStyle: CommitStyle = .emoji

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CommitCategory.allCases, id: \.self) { category in
                Text(displayLabel(for: category))
                    .tag(category as CommitCategory?)
            }
        }
        .frame(width: 135)
        .pickerStyle(.automatic)
    }

    private func displayLabel(for category: CommitCategory) -> String {
        if commitStyle.includeEmoji {
            return category.label
        } else if commitStyle.isLowercase {
            return category.title.lowercased()
        } else {
            return category.title
        }
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
