import GitOKAppCore
import GitOKUI
import SwiftUI

// MARK: - ProjectRow

/// 项目行视图，支持选中态和 hover 态
public struct ProjectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public var body: some View {
        AppListRow(isSelected: isSelected, action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "当前项目" : "切换到此项目")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
