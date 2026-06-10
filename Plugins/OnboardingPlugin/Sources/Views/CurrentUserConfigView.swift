import GitOKAppCore
import Foundation
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

private enum CurrentUserConfigBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

/// 显示当前项目 Git 用户配置的视图组件
public struct CurrentUserConfigView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "👤"

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

    public var body: some View {
        AppSettingSection(title: "Git 用户配置", titleAlignment: .leading) {
            VStack(spacing: 0) {
                userNameRow
                Divider()
                    .padding(.vertical, 8)
                userEmailRow
            }
        }
        .onAppear(perform: loadUserInfo)
        .onGitUserConfigUpdated(perform: loadUserInfo)
    }

    // MARK: - View Components

    private var userNameRow: some View {
        AppSettingRow(
            title: "用户名",
            description: userName.isEmpty ? "未配置 user.name" : userName,
            icon: .iconUser
        ) {
            if isLoading {
                AppLoadingOverlay(size: .small)
            }
        }
    }

    private var userEmailRow: some View {
        AppSettingRow(
            title: "邮箱",
            description: userEmail.isEmpty ? "未配置 user.email" : userEmail,
            icon: .iconMail
        ) {
            if isLoading {
                AppLoadingOverlay(size: .small)
            }
        }
    }

    // MARK: - Load Data

    private func loadUserInfo() {
        let projectTransfer = CurrentUserConfigBackgroundRunner.UnsafeTransfer(value: project)
        isLoading = true

        Task.detached(priority: .utility) {
            do {
                let loadedName = try await projectTransfer.value.getUserNameAsync()
                let loadedEmail = try await projectTransfer.value.getUserEmailAsync()

                Task { @MainActor in
                    userName = loadedName
                    userEmail = loadedEmail
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)Loaded Git user config - name: \(loadedName), email: \(loadedEmail)")
                    }
                }
            } catch {
                let message = error.localizedDescription

                Task { @MainActor in
                    userName = ""
                    userEmail = ""
                    isLoading = false

                    if Self.verbose {
                        os_log(.error, "\(Self.t)Failed to load Git user config: \(message)")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

