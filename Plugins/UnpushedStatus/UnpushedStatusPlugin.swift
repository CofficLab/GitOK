import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 未推送提交状态插件
/// 通过根视图包裹来跟踪并更新项目的未推送提交数量
class UnpushedStatusPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Unpushed Status"

    /// 插件描述
    static var description: String = String(localized: "显示未推送提交数量", table: "UnpushedStatus")

    /// 插件图标名称
    static var iconName: String = "arrow.up.circle"

    /// 插件是否可配置
    static var allowUserToggle = true

    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 插件注册顺序
    static var order: Int = 25

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 是否启用详细日志输出
    private let verbose = false

    /// 单例实例
    static var shared = UnpushedStatusPlugin()

    override init() {
        super.init()
    }

    /// 添加根视图包裹
    /// 监听项目变化，自动更新未推送提交数量到 ProjectVM
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        AnyView(
            UnpushedStatusRootView(content: content())
        )
    }
}

// MARK: - UnpushedStatusRootView

/// 未推送状态根视图
/// 包裹整个应用内容，监听项目变化并更新未推送提交数量
struct UnpushedStatusRootView<Content: View>: View, SuperLog {
    nonisolated static let emoji = "📤"
    nonisolated static let verbose = false

    let content: Content

    @EnvironmentObject var vm: ProjectVM

    var body: some View {
        content
            .onAppear {
                refreshUnpushedCount()
            }
            .onChange(of: vm.project) { _, _ in
                refreshUnpushedCount()
            }
            .onProjectDidChangeBranch { _ in
                refreshUnpushedCount()
            }
            .onProjectDidCommit { _ in
                refreshUnpushedCount()
            }
            .onProjectDidPush { _ in
                refreshUnpushedCount()
            }
            .onProjectDidPull { _ in
                refreshUnpushedCount()
            }
            .onApplicationDidBecomeActive {
                refreshUnpushedCount()
            }
    }

    private func refreshUnpushedCount() {
        guard let project = vm.project else {
            vm.updateUnpushedCommits(0, hashes: [])
            return
        }

        Task.detached(priority: .userInitiated) {
            do {
                let unpushed = try await project.getUnPushedCommits()
                let count = unpushed.count
                let hashes = unpushed.map { $0.hash }

                await MainActor.run {
                    vm.updateUnpushedCommits(count, hashes: hashes)
                }

                if Self.verbose {
                    os_log("\(Self.t)📊 Unpushed count updated: \(count)")
                }
            } catch {
                await MainActor.run {
                    vm.updateUnpushedCommits(0, hashes: [])
                }
                if Self.verbose {
                    os_log(.error, "\(Self.t)❌ Failed to refresh unpushed count: \(error)")
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

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}