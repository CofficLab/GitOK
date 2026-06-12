import SwiftUI

/// 提交正文信息显示组件
/// 显示提交的详细描述信息，支持文本选择
public struct CommitBodyInfo: View {
    /// 提交对象
    let bodyText: String

    public init(bodyText: String) {
        self.bodyText = bodyText
    }

    public var body: some View {
        // Commit body（如果有）
        if !bodyText.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                Text(bodyText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(10)
                    .textSelection(.enabled)

                Spacer()
            }

            Divider()
        }
    }
}
