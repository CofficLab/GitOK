import GitCoreKit
import MagicAlert
import SwiftUI

public struct GitDetailNoLocalChangesView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("没有本地更改")
                .font(.title3)
                .fontWeight(.semibold)
            Text("全部更改已提交到本地仓库")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

public struct GitDetailNotRepositoryView: View {
    @EnvironmentObject var vm: ProjectVM
    @State private var isInitializing = false

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("当前目录不是 Git 仓库")
                .font(.title3)
                .fontWeight(.semibold)

            Button(isInitializing ? "初始化中..." : "初始化 Git 仓库") {
                initializeGitRepository()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isInitializing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
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
