import GitOKAppCore
import SwiftUI
import KitGitOKCore
import KitGitOKSupport
import KernelCore

/// Git 菜单命令：集中暴露常用仓库操作和快捷键。
public struct GitCommand: Commands, SuperLog {
    public nonisolated static let emoji = "⌘"
    public nonisolated static let verbose = false

    private let kernel: KernelCoreContainer

    public init(kernel: KernelCoreContainer) {
        self.kernel = kernel
    }

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

    public var body: some Commands {
        #if os(macOS)
        CommandMenu("Git") {
            Button(String(localized: "Refresh Status")) {
                kernel.resolveProvider((any GitOKGitCommandServicing).self)?.performGitCommand(.refresh)
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(!hasGitProject)

            Divider()

            Button("Fetch") {
                kernel.resolveProvider((any GitOKGitCommandServicing).self)?.performGitCommand(.fetch)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(!hasGitProject)

            Button("Pull") {
                kernel.resolveProvider((any GitOKGitCommandServicing).self)?.performGitCommand(.pull)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!canPull)

            Button("Push") {
                kernel.resolveProvider((any GitOKGitCommandServicing).self)?.performGitCommand(.push)
            }
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(!canPush)

            Divider()

            Button(String(localized: "Repository Settings...")) {
                kernel.resolveProvider((any GitOKNavigationServicing).self)?.openRepositorySettings()
            }
            .keyboardShortcut(",", modifiers: [.command, .option])
            .disabled(!hasGitProject)
        }
        #endif
    }
}
