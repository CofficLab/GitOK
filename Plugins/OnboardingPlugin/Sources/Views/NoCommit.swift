import GitOKAppCore
import SwiftUI

/// 无提交记录提示视图
/// 当 Git 仓库没有提交记录时显示此视图
public struct NoCommit: View {
    public var body: some View {
        GuideView(
            systemImage: "doc.text.magnifyingglass",
            title: String(localized: "select_commit_title"),
            subtitle: String(localized: "select_commit_description")
        )
    }
}
