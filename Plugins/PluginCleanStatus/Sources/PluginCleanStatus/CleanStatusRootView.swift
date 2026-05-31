import GitCoreKit
import GitOKPluginKit
import SwiftUI

/// 桥接层：从 Environment 读取数据，构建 CleanStatusPluginContext 后传给内部视图。
///
/// 这是唯一接触 @Environment 的地方，内部视图全部通过 context 获取数据。
struct CleanStatusRootView: View {
    let content: AnyView

    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.gitOKCleanStatusUpdateHandler) private var updateCleanStatus

    var body: some View {
        let context = CleanStatusPluginContext(
            projectURL: projectURL,
            updateCleanStatus: updateCleanStatus
        )
        CleanStatusCheckerView(content: content, context: context)
    }
}

/// 实际业务视图：通过 context 获取所有数据，不依赖任何 @Environment。
struct CleanStatusCheckerView: View {
    let content: AnyView
    let context: CleanStatusPluginContext

    @State private var lastProjectURL: URL?

    var body: some View {
        content
            .onAppear(perform: checkCleanStatus)
            .onChange(of: context.projectURL) { _, _ in checkCleanStatus() }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusAppDidBecomeActive)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidChangeBranch)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidCommit)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidPush)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidPull)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidMerge)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidSync)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidAddFiles)) { _ in
                context.updateCleanStatus(false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectGitIndexDidChange)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectGitHeadDidChange)) { _ in
                checkCleanStatus()
            }
    }

    private func checkCleanStatus() {
        guard let projectURL = context.projectURL else {
            lastProjectURL = nil
            context.updateCleanStatus(true)
            return
        }

        lastProjectURL = projectURL

        Task {
            let isClean: Bool
            do {
                isClean = try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).statusEntries().isEmpty
                }.value
            } catch {
                isClean = true
            }

            guard lastProjectURL == context.projectURL else { return }
            context.updateCleanStatus(isClean)
        }
    }
}
