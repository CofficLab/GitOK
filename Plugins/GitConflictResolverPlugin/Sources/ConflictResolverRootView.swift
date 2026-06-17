import GitCoreKit
import GitOKCoreKit
import SwiftUI

struct ConflictResolverRootView: View {
    let content: AnyView
    let projectURL: URL?
    let isGitRepository: Bool

    @State private var status = ConflictResolverRootStatus()
    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            content

            if status.shouldBlockApp, let projectURL {
                blockingOverlay(projectURL: projectURL)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: status.shouldBlockApp)
        .onAppear(perform: refreshConflictStatus)
        .onChange(of: projectURL) {
            refreshConflictStatus()
        }
        .onChange(of: isGitRepository) {
            refreshConflictStatus()
        }
        .onDisappear {
            checkTask?.cancel()
            checkTask = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverAppDidBecomeActive)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectDidChangeBranch)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectDidCommit)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectDidMerge)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectDidPull)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectGitHeadDidChange)) { _ in
            refreshConflictStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginConflictResolverProjectGitIndexDidChange)) { _ in
            refreshConflictStatus()
        }
    }

    private func blockingOverlay(projectURL: URL) -> some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(DesignTokens.Color.semantic.warning)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(GitConflictResolverPluginLocalization.string("Merge paused by conflicts"))
                            .font(.title2.weight(.semibold))
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text(status.message)
                            .font(.body)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if status.isChecking {
                        AppLoadingOverlay(size: .small)
                            .frame(width: 28, height: 28)
                    }
                }

                ConflictResolverList(projectURL: projectURL) { isMerging, conflictCount in
                    updateStatus(isMerging: isMerging, conflictCount: conflictCount, isChecking: false)
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(minWidth: 720, idealWidth: 920, maxWidth: 1040)
            .frame(maxHeight: 760)
            .gitOKUISurface(cornerRadius: DesignTokens.Radius.md)
            .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 18)
            .padding(DesignTokens.Spacing.xl)
        }
    }

    private func refreshConflictStatus() {
        checkTask?.cancel()

        guard isGitRepository, let projectURL else {
            status = ConflictResolverRootStatus()
            return
        }

        let expectedURL = projectURL.standardizedFileURL
        if status.shouldBlockApp {
            status.isChecking = true
        }

        checkTask = Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: expectedURL)
                let isMerging = try repository.isMerging()
                let conflictCount = isMerging ? (try repository.getMergeConflictFiles().count) : 0

                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    checkTask = nil
                    updateStatus(isMerging: isMerging, conflictCount: conflictCount, isChecking: false)
                }
            } catch {
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    checkTask = nil
                    updateStatus(isMerging: false, conflictCount: 0, isChecking: false)
                }
            }
        }
    }

    @MainActor
    private func updateStatus(isMerging: Bool, conflictCount: Int, isChecking: Bool) {
        status = ConflictResolverRootStatus(
            isMerging: isMerging,
            conflictCount: conflictCount,
            isChecking: isChecking
        )
    }
}

private struct ConflictResolverRootStatus: Equatable {
    var isMerging = false
    var conflictCount = 0
    var isChecking = false

    var shouldBlockApp: Bool {
        isMerging
    }

    var message: String {
        if conflictCount > 0 {
            return String(
                format: GitConflictResolverPluginLocalization.string("Resolve %d conflicted files before using the rest of GitOK."),
                conflictCount
            )
        }

        return GitConflictResolverPluginLocalization.string("Resolve the merge state before using the rest of GitOK.")
    }
}
