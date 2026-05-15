import MagicKit
import OSLog
import SwiftUI

struct GitWatcherRootView<Content: View>: View, SuperLog {
    nonisolated static var emoji: String { "GW" }
    nonisolated static var verbose: Bool { false }

    let content: Content

    @EnvironmentObject var vm: ProjectVM
    @StateObject private var coordinator = GitWatcherCoordinator()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                coordinator.update(project: vm.project)
            }
            .onChange(of: vm.project) { _, project in
                coordinator.update(project: project)
            }
            .onDisappear {
                coordinator.stop()
            }
    }
}

@MainActor
private final class GitWatcherCoordinator: ObservableObject, SuperLog {
    nonisolated static var emoji: String { "GW" }
    nonisolated static let verbose = false

    private var project: Project?
    private var watcher: GitDirectoryWatcher?
    private var debounceTask: Task<Void, Never>?
    private var lastHead: String?
    private var watchedGitDirectory: String?

    func update(project: Project?) {
        guard self.project?.path != project?.path else { return }

        stop()
        self.project = project

        guard let project else { return }
        guard project.isGit() else { return }

        do {
            let gitDirectory = try GitDirectoryResolver.resolveGitDirectory(for: project.path)
            watchedGitDirectory = gitDirectory.path
            lastHead = GitDirectoryResolver.readHeadHash(gitDirectory: gitDirectory)

            watcher = try GitDirectoryWatcher(url: gitDirectory) { [weak self] in
                Task { @MainActor in
                    self?.scheduleChangeCheck()
                }
            }

            if Self.verbose {
                os_log("\(self.t)Watching git directory: \(gitDirectory.path)")
            }
        } catch {
            if Self.verbose {
                os_log(.error, "\(self.t)Failed to watch git directory: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        watcher?.stop()
        watcher = nil
        watchedGitDirectory = nil
        lastHead = nil
    }

    private func scheduleChangeCheck() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.checkForHeadChange()
        }
    }

    private func checkForHeadChange() {
        guard let project, let watchedGitDirectory else { return }

        let gitDirectory = URL(fileURLWithPath: watchedGitDirectory, isDirectory: true)
        let currentHead = GitDirectoryResolver.readHeadHash(gitDirectory: gitDirectory)
        let previousHead = lastHead
        let headChanged = currentHead != previousHead
        lastHead = currentHead

        var additionalInfo: [String: Any] = [
            "gitPath": watchedGitDirectory,
            "changeKind": headChanged ? "head" : "metadata",
            "headChanged": headChanged
        ]

        if let previousHead {
            additionalInfo["previousHead"] = previousHead
        }

        if let currentHead {
            additionalInfo["head"] = currentHead
        }

        project.postEvent(
            name: .projectGitDirectoryDidChange,
            operation: "gitDirectoryChanged",
            additionalInfo: additionalInfo
        )
    }
}
