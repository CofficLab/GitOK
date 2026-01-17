import Foundation
import LibGit2Swift
import MagicKit
import MagicUI
import OSLog
import SwiftUI

// MARK: - Notifications

extension Notification.Name {
    static let didUpdateGitUserConfig = Notification.Name("didUpdateGitUserConfig")
}


/// 显示当前项目 Git 用户配置的视图组件
struct CurrentUserConfigView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    /// 当前用户名
    @State private var userName: String = ""

    /// 当前用户邮箱
    @State private var userEmail: String = ""

    /// 是否正在加载
    @State private var isLoading = true

    var body: some View {
        MagicSettingSection(title: "Git 用户配置", titleAlignment: .leading) {
            VStack(spacing: 0) {
                userNameRow
                Divider()
                userEmailRow
            }
        }
        .onAppear(perform: loadUserInfo)
        .onGitUserConfigUpdated(perform: loadUserInfo)
    }

    // MARK: - View Components

    private var userNameRow: some View {
        MagicSettingRow(
            title: "用户名",
            description: userName.isEmpty ? "未配置 user.name" : userName,
            icon: .iconUser
        ) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private var userEmailRow: some View {
        MagicSettingRow(
            title: "邮箱",
            description: userEmail.isEmpty ? "未配置 user.email" : userEmail,
            icon: .iconMail
        ) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Load Data

    private func loadUserInfo() {
        isLoading = true

        do {
            userName = try project.getUserName()
            userEmail = try project.getUserEmail()

            if Self.verbose {
                os_log("\(Self.t)Loaded Git user config - name: \(userName), email: \(userEmail)")
            }
        } catch {
            userName = ""
            userEmail = ""

            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load Git user config: \(error)")
            }
        }

        isLoading = false
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
