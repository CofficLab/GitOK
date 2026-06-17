import GitCoreKit
import GitOKAppCore
import GitOKSupportKit
import MagicAlert
import OSLog
import SwiftUI

struct DetailNotGitRepositoryView: View, SuperLog, SuperEvent {
    nonisolated static let emoji = "⚠️"
    nonisolated static let verbose = false

    @EnvironmentObject private var vm: ProjectVM
    @State private var isInitializing = false

    var body: some View {
        DetailGuideView(
            systemImage: "exclamationmark.triangle",
            title: "当前目录不是 Git 仓库",
            action: initializeGitRepository,
            actionLabel: isInitializing ? "初始化中..." : "初始化 Git 仓库"
        )
    }

    private func initializeGitRepository() {
        guard let project = vm.project else {
            alert_error("项目不存在")
            return
        }

        isInitializing = true

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI.initialize(at: URL(fileURLWithPath: project.path))
                await MainActor.run {
                    isInitializing = false
                    vm.refreshCurrentProjectGitRepositoryState(reason: "Git initialized")
                }
            } catch {
                await MainActor.run {
                    isInitializing = false
                    alert_error("初始化 Git 仓库失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
