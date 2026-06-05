import SwiftUI
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
            Button("刷新状态") {
                NotificationCenter.default.post(name: .gitCommandRefresh, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(!hasGitProject)

            Divider()

            Button("Fetch") {
                NotificationCenter.default.post(name: .gitCommandFetch, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(!hasGitProject)

            Button("Pull") {
                NotificationCenter.default.post(name: .gitCommandPull, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!canPull)

            Button("Push") {
                NotificationCenter.default.post(name: .gitCommandPush, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(!canPush)

            Divider()

            Button("仓库设置...") {
                NotificationCenter.default.post(name: .gitCommandRepositorySettings, object: nil)
            }
            .keyboardShortcut(",", modifiers: [.command, .option])
            .disabled(!hasGitProject)
        }
        #endif
    }
}
