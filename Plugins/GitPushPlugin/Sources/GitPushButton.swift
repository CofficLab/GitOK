import AppKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct GitPushButton: View {
    let projectURL: URL
    let isGitRepository: Bool
    let trackingStatus: GitOKRemoteTrackingStatus
    let updateRemoteTracking: GitOKRemoteTrackingUpdateHandler
    @State private var working = false
    @State private var showPushNeedsFetchAlert = false

    public init(
        projectURL: URL,
        isGitRepository: Bool,
        trackingStatus: GitOKRemoteTrackingStatus,
        updateRemoteTracking: @escaping GitOKRemoteTrackingUpdateHandler
    ) {
        self.projectURL = projectURL
        self.isGitRepository = isGitRepository
        self.trackingStatus = trackingStatus
        self.updateRemoteTracking = updateRemoteTracking
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button {
                perform(primaryAction, projectURL: projectURL)
            } label: {
                HStack(spacing: 6) {
                    primaryAction.icon
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 16, height: 16)

                    Text(primaryAction.title)
                        .font(.caption)
                        .lineLimit(1)

                    if let badgeText {
                        Text(badgeText)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    run(.fetch, projectURL: projectURL)
                } label: {
                    Label(GitPushPluginLocalization.string("Fetch origin"), systemImage: "arrow.clockwise")
                }

                Button {
                    run(.pull, projectURL: projectURL)
                } label: {
                    Label(GitPushPluginLocalization.string("Pull origin"), systemImage: "arrow.down")
                }
                .disabled(trackingStatus.hasUpstream != true)

                Button {
                    run(.push, projectURL: projectURL)
                } label: {
                    Label(pushTitle, systemImage: "arrow.up")
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .frame(width: 18, height: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .frame(width: 148, height: 36)
        .background(.quaternary.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .fixedSize(horizontal: true, vertical: false)
        .disabled(working)
        .help(primaryAction.help)
        .alert(GitPushPluginLocalization.string("New commits on remote"), isPresented: $showPushNeedsFetchAlert) {
            Button(GitPushPluginLocalization.string("Fetch")) {
                run(.fetch, projectURL: projectURL)
            }
            Button(GitPushPluginLocalization.string("Cancel"), role: .cancel) {}
        } message: {
            Text(GitPushPluginLocalization.string("Cannot push because the remote branch has commits you don't have locally. Please Fetch first, then Pull or Rebase before pushing again."))
        }
    }

    private var primaryAction: GitPushPrimaryAction {
        GitPushPrimaryAction.primaryAction(for: trackingStatus)
    }

    private var pushTitle: String {
        trackingStatus.hasUpstream
            ? GitPushPluginLocalization.string("Push origin")
            : GitPushPluginLocalization.string("Publish branch")
    }

    private var badgeText: String? {
        GitPushPrimaryAction.badgeText(for: trackingStatus)
    }

    private func perform(_ action: GitPushPrimaryAction, projectURL: URL) {
        run(action, projectURL: projectURL)
    }

    private func run(_ action: GitPushPrimaryAction, projectURL: URL) {
        working = true
        Task.detached {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                switch action {
                case .fetch:
                    try repository.fetch()
                case .pull:
                    try repository.pull()
                case .push:
                    try repository.push()
                }

                let nextStatus = try? repository.aheadBehind()
                await MainActor.run {
                    working = false
                    if let nextStatus {
                        updateRemoteTracking(
                            GitOKRemoteTrackingStatus(
                                ahead: nextStatus.ahead,
                                behind: nextStatus.behind,
                                hasUpstream: nextStatus.hasUpstream
                            ),
                            Date()
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    working = false
                    if action == .push, error.localizedDescription.localizedCaseInsensitiveContains("fetch") {
                        showPushNeedsFetchAlert = true
                    } else {
                        showError(error)
                    }
                }
            }
        }
    }

    @MainActor
    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = GitPushPluginLocalization.string("Git sync failed")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

public enum GitPushPrimaryAction: Equatable, Sendable {
    case fetch
    case pull
    case push

    public static func primaryAction(for status: GitOKRemoteTrackingStatus) -> GitPushPrimaryAction {
        if status.hasUpstream, status.behind > 0 {
            return .pull
        }

        if status.hasUpstream, status.ahead == 0 {
            return .fetch
        }

        return .push
    }

    public static func badgeText(for status: GitOKRemoteTrackingStatus) -> String? {
        guard status.hasUpstream else { return nil }

        if status.ahead > 0, status.behind > 0 {
            return "↑\(status.ahead) ↓\(status.behind)"
        }

        if status.ahead > 0 {
            return "↑\(status.ahead)"
        }

        if status.behind > 0 {
            return "↓\(status.behind)"
        }

        return nil
    }

    var icon: Image {
        switch self {
        case .fetch:
            Image(systemName: "arrow.clockwise")
        case .pull:
            Image(systemName: "arrow.down")
        case .push:
            Image(systemName: "arrow.up")
        }
    }

    var title: String {
        switch self {
        case .fetch:
            GitPushPluginLocalization.string("Fetch origin")
        case .pull:
            GitPushPluginLocalization.string("Pull origin")
        case .push:
            GitPushPluginLocalization.string("Push origin")
        }
    }

    var help: String {
        switch self {
        case .fetch:
            GitPushPluginLocalization.string("Branch is up to date, click Fetch to check for remote updates")
        case .pull:
            GitPushPluginLocalization.string("New commits on remote, click Pull; Fetch or Push available in menu")
        case .push:
            GitPushPluginLocalization.string("Commits ready to push")
        }
    }
}
