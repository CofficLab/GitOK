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
    private var lastSnapshot: GitDirectorySnapshot?
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
            lastSnapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)

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
        lastSnapshot = nil
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
        let currentSnapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)
        let previousSnapshot = lastSnapshot
        let headChanged = currentSnapshot.head != previousSnapshot?.head
        let indexChanged = currentSnapshot.index != previousSnapshot?.index
        let stashChanged = currentSnapshot.stash != previousSnapshot?.stash
        let refsChanged = currentSnapshot.refs != previousSnapshot?.refs

        guard headChanged || indexChanged || stashChanged || refsChanged else {
            return
        }

        lastSnapshot = currentSnapshot

        var additionalInfo: [String: Any] = [
            "gitPath": watchedGitDirectory,
            "changeKind": changeKind(
                headChanged: headChanged,
                indexChanged: indexChanged,
                stashChanged: stashChanged,
                refsChanged: refsChanged
            ),
            "headChanged": headChanged,
            "indexChanged": indexChanged,
            "stashChanged": stashChanged,
            "refsChanged": refsChanged
        ]

        if let previousHead = previousSnapshot?.head {
            additionalInfo["previousHead"] = previousHead
        }

        if let currentHead = currentSnapshot.head {
            additionalInfo["head"] = currentHead
        }

        project.postEvent(
            name: .projectGitDirectoryDidChange,
            operation: "gitDirectoryChanged",
            additionalInfo: additionalInfo
        )

        postSpecificChangeEvents(
            project: project,
            headChanged: headChanged,
            indexChanged: indexChanged,
            stashChanged: stashChanged,
            refsChanged: refsChanged,
            additionalInfo: additionalInfo
        )
    }

    private func changeKind(headChanged: Bool, indexChanged: Bool, stashChanged: Bool, refsChanged: Bool) -> String {
        let changes = [
            headChanged ? "head" : nil,
            indexChanged ? "index" : nil,
            stashChanged ? "stash" : nil,
            refsChanged ? "refs" : nil
        ].compactMap { $0 }

        return changes.count == 1 ? changes[0] : "multiple"
    }

    private func postSpecificChangeEvents(
        project: Project,
        headChanged: Bool,
        indexChanged: Bool,
        stashChanged: Bool,
        refsChanged: Bool,
        additionalInfo: [String: Any]
    ) {
        if headChanged {
            project.postEvent(
                name: .projectGitHeadDidChange,
                operation: "gitHeadChanged",
                additionalInfo: additionalInfo
            )
        }

        if indexChanged {
            project.postEvent(
                name: .projectGitIndexDidChange,
                operation: "gitIndexChanged",
                additionalInfo: additionalInfo
            )
        }

        if stashChanged {
            project.postEvent(
                name: .projectGitStashDidChange,
                operation: "gitStashChanged",
                additionalInfo: additionalInfo
            )
        }

        if refsChanged {
            project.postEvent(
                name: .projectGitRefsDidChange,
                operation: "gitRefsChanged",
                additionalInfo: additionalInfo
            )
        }
    }
}
