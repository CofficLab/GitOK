import SwiftUI

/// Commit 风格选择器组件
/// 提供提交风格的下拉选择功能，并自动保存到项目配置
public struct CommitStylePicker: View {
    /// 绑定到外部的选中风格
    @Binding var selection: CommitStyle

    private let onSelectionChange: (CommitStyle) -> Void

    public init(
        selection: Binding<CommitStyle>,
        onSelectionChange: @escaping (CommitStyle) -> Void = { _ in }
    ) {
        self._selection = selection
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(CommitStyle.allCases, id: \.self) { style in
                Text(style.label)
                    .tag(style as CommitStyle?)
            }
        }
        .frame(width: 120)
        .pickerStyle(.automatic)
        .onChange(of: selection) { _, newValue in
            onSelectionChange(newValue)
        }
    }
}
