import GitOKAppCore
import GitCoreKit
import GitOKUI
import GitOKSupportKit
import SwiftUI

/// 显示当前分支信息的视图组件
public struct BranchInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "🌿"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 分支实例
    let branch: GitBranch

    public var body: some View {
        AppSettingSection(title: "当前分支", titleAlignment: .leading) {
            AppSettingRow(
                title: branch.name,
                description: "当前检出的分支",
                icon: .iconLog
            ) {
                // 分支信息通常不需要操作按钮
            }
        }
    }
}

// MARK: - Preview

