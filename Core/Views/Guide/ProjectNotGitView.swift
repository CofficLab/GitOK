import MagicAlert
import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 非 Git 项目提示视图
/// 当当前目录不是 Git 仓库时显示此视图
struct ProjectNotGitView: View, SuperLog, SuperThread, SuperEvent {
    /// emoji 标识符
    nonisolated static let emoji = "⚠️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 环境对象：项目状态管理
    @EnvironmentObject var vm: ProjectVM

    /// 是否正在初始化
    @State private var isInitializing = false

    var body: some View {
        GuideView(
            systemImage: "exclamationmark.triangle",
            title: "当前目录不是 Git 仓库",
            action: initializeGitRepository,
            actionLabel: isInitializing ? "初始化中..." : "初始化 Git 仓库"
        )
    }
}

// MARK: - Actions

extension ProjectNotGitView {
    /// 初始化 Git 仓库
    func initializeGitRepository() {
        guard let project = vm.project else {
            os_log(.error, "\(Self.t)❌ 项目不存在")
            alert_error("项目不存在")
            return
        }

        isInitializing = true

        Task.detached(priority: .userInitiated) {
            do {
                if Self.verbose {
                    os_log("\(Self.t)🔧 Initializing Git repository at: \(project.path)")
                }

                try await initializeGit(at: project.path)

                await MainActor.run {
                    isInitializing = false

                    if Self.verbose {
                        os_log("\(Self.t)✅ Git repository initialized successfully")
                    }

                    // 更新项目的 Git 状态缓存并刷新界面
                    Task {
                        await project.updateIsGitRepoCache()

                        // 重新设置项目以触发 ContentView 的 updateCachedViews
                        await MainActor.run {
                            if let currentProject = vm.project {
                                vm.setProject(currentProject, reason: "Git initialized")
                            }
                        }
                    }
                }
            } catch let error {
                await MainActor.run {
                    isInitializing = false
                    os_log(.error, "\(Self.t)❌ 初始化 Git 仓库失败: \(error.localizedDescription)")
                    alert_error("初始化 Git 仓库失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 在指定路径初始化 Git 仓库
    /// - Parameter path: 项目路径
    private func initializeGit(at path: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["init", path]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "com.gitok.git",
                        code: Int(process.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: "git init 命令执行失败"]
                    ))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
