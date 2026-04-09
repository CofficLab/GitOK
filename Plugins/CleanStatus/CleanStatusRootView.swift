import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// CleanStatus Root View
/// 监听项目变化并更新 isClean 状态到 ProjectVM
struct CleanStatusRootView<Content: View>: View, SuperLog {
    nonisolated static var emoji: String { "✅" }
    private let verbose = false

    let content: Content

    @EnvironmentObject var vm: ProjectVM

    /// 上一次检查的项目路径
    @State private var lastProjectPath: String = ""

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                if verbose {
                    os_log("\(Self.t) CleanStatusRootView appeared")
                }
                checkCleanStatus()
            }
            .onChange(of: vm.project) { _, _ in
                if verbose {
                    os_log("\(Self.t) Project changed")
                }
                checkCleanStatus()
            }
            .onProjectDidChangeBranch { _ in
                if verbose {
                    os_log("\(Self.t) Branch changed")
                }
                checkCleanStatus()
            }
            .onProjectDidCommit { _ in
                if verbose {
                    os_log("\(Self.t) Commit happened")
                }
                checkCleanStatus()
            }
            .onProjectDidPush { _ in
                if verbose {
                    os_log("\(Self.t) Push happened")
                }
                checkCleanStatus()
            }
            .onProjectDidPull { _ in
                if verbose {
                    os_log("\(Self.t) Pull happened")
                }
                checkCleanStatus()
            }
            .onProjectDidAddFiles { _ in
                if verbose {
                    os_log("\(Self.t) Files added")
                }
                // 添加文件后，项目一定不 clean
                vm.updateIsClean(false)
            }
            .onProjectDidMerge { _ in
                if verbose {
                    os_log("\(Self.t) Merge happened")
                }
                checkCleanStatus()
            }
            .onProjectDidSync { _ in
                if verbose {
                    os_log("\(Self.t) Sync happened")
                }
                checkCleanStatus()
            }
            .onApplicationDidBecomeActive {
                if verbose {
                    os_log("\(Self.t) App became active")
                }
                checkCleanStatus()
            }
    }

    /// 检查并更新项目的 clean 状态
    private func checkCleanStatus() {
        guard let project = vm.project else {
            // 没有项目时，视为 clean
            if verbose {
                os_log("\(Self.t) No project, set isClean = true")
            }
            vm.updateIsClean(true)
            return
        }

        // 避免重复检查同一个项目（如果上次检查的结果不是 clean，可以重新检查）
        // if project.path == lastProjectPath && vm.isClean != true {
        //     if verbose {
        //         os_log("\(Self.t) Same project \(project.path), skip check")
        //     }
        //     return
        // }

        lastProjectPath = project.path

        Task.detached(priority: .userInitiated) { [weak vm] in
            guard let vm = vm else { return }

            let isClean: Bool
            do {
                isClean = try project.isClean(verbose: false)
            } catch {
                if verbose {
                    os_log(.error, "\(Self.t) Error checking clean status: \(error.localizedDescription)")
                }
                isClean = true // 出错时默认为 clean
            }

            await MainActor.run {
                if verbose {
                    os_log("\(Self.t) Project \(project.path) isClean = \(isClean)")
                }
                vm.updateIsClean(isClean)
            }
        }
    }
}
