import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 未推送状态根视图
/// 包裹整个应用内容，监听项目变化并更新未推送提交数量
struct UnpushedStatusRootView<Content: View>: View, SuperLog {
    nonisolated static var emoji: String { "📤" }
    private let verbose = false

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

                if self.verbose {
                    os_log("\(Self.t)📊 Unpushed count updated: \(count)")
                }
            } catch {
                await MainActor.run {
                    vm.updateUnpushedCommits(0, hashes: [])
                }
                if self.verbose {
                    os_log(.error, "\(Self.t)❌ Failed to refresh unpushed count: \(error)")
                }
            }
        }
    }
}
