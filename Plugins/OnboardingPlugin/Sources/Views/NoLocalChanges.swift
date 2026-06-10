import GitOKAppCore
import SwiftUI

/// 无本地更改提示视图
/// 当 Git 仓库没有本地更改时显示此视图
public struct NoLocalChanges: View {
    public init() {}

    public var body: some View {
        GuideView(
            systemImage: "checkmark.circle",
            title: "没有本地更改",
            subtitle: "全部更改已提交到本地仓库"
        ).setIconColor(.green)
    }
}
