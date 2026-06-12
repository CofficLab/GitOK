import GitOKAppCore
import SwiftUI
import GitOKCoreKit
import GitOKSupportKit

/// Git 菜单命令：集中暴露常用仓库操作和快捷键。
struct GitCommand: Commands, SuperLog {
    nonisolated static let emoji = "⌘"
    nonisolated static let verbose = false

    @FocusedObject private var projectVM: ProjectVM?

    private var hasGitProject: Bool {
        projectVM?.currentProjectIsGitRepository == true
    }

    private var canPush: Bool {
        hasGitProject && (projectVM?.aheadCount ?? 0) > 0
    }

    private var canPull: Bool {
        hasGitProject && (projectVM?.behindCount ?? 0) > 0
    }

    var body: some Commands {
        #if os(macOS)
        CommandMenu("Git") {
            Button(String(localized: "Refresh Status")) {
                RootContainer.shared.gitCoreService.performGitCommand(.refresh)
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(!hasGitProject)

            Divider()

            Button("Fetch") {
                RootContainer.shared.gitCoreService.performGitCommand(.fetch)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(!hasGitProject)

            Button("Pull") {
                RootContainer.shared.gitCoreService.performGitCommand(.pull)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!canPull)

            Button("Push") {
                RootContainer.shared.gitCoreService.performGitCommand(.push)
            }
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(!canPush)

            Divider()

            Button(String(localized: "Repository Settings...")) {
                RootContainer.shared.navigationService.openRepositorySettings()
            }
            .keyboardShortcut(",", modifiers: [.command, .option])
            .disabled(!hasGitProject)
        }
        #endif
    }
}
