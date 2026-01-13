import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示Git用户信息的视图组件
struct UserInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 当前用户名
    let currentUser: String

    /// 当前用户邮箱
    let currentEmail: String

    /// 显示用户配置表单的回调
    let onShowUserConfig: () -> Void

    var body: some View {
        MagicSettingSection(title: "Git 用户信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                MagicSettingRow(
                    title: currentUser.isEmpty ? "未配置" : currentUser,
                    description: currentUser.isEmpty ? "点击配置 Git 用户信息" : currentEmail,
                    icon: .iconUser
                ) {
                    MagicButton.simple {
                        onShowUserConfig()
                    }
                    .magicIcon(.iconSettings)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}