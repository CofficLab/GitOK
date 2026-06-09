import GitOKCoreKit
import SwiftUI

struct GitWatcherRootView: View {
    let content: AnyView
    let projectURL: URL?
    let gitDirectoryChangeHandler: GitOKGitDirectoryChangeHandler

    @StateObject private var coordinator = GitWatcherCoordinator()

    var body: some View {
        content
            .onAppear {
                coordinator.update(projectURL: projectURL, onChange: gitDirectoryChangeHandler)
            }
            .onDisappear {
                coordinator.stop()
            }
    }
}

@MainActor
final class GitWatcherCoordinator: ObservableObject {
    private var projectURL: URL?
    private var watcher: GitDirectoryWatcher?
    private var setupTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var lastSnapshot: GitDirectorySnapshot?
    private var watchedGitDirectory: String?
    private var onChange: GitOKGitDirectoryChangeHandler = { _ in }

    func update(projectURL: URL?, onChange: @escaping GitOKGitDirectoryChangeHandler) {
        self.onChange = onChange
        guard self.projectURL?.standardizedFileURL != projectURL?.standardizedFileURL else { return }

        stop()
        self.projectURL = projectURL

        guard let projectURL else { return }
        let expectedProjectURL = projectURL.standardizedFileURL

        setupTask = Task { [weak self] in
            do {
                let (gitDirectory, snapshot) = try await Task.detached(priority: .utility) {
                    let gitDirectory = try GitDirectoryResolver.resolveGitDirectory(for: expectedProjectURL)
                    return (gitDirectory, GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory))
                }.value

                await MainActor.run {
                    guard let self,
                          self.projectURL?.standardizedFileURL == expectedProjectURL else { return }

                    do {
                        self.watchedGitDirectory = gitDirectory.path
                        self.lastSnapshot = snapshot

                        self.watcher = try GitDirectoryWatcher(url: gitDirectory) { [weak self] in
                            Task { @MainActor in
                                self?.scheduleChangeCheck()
                            }
                        }
                    } catch {
                        self.stop()
                    }
                }
            } catch {
                await MainActor.run {
                    guard self?.projectURL?.standardizedFileURL == expectedProjectURL else { return }
                    self?.stop()
                }
            }
        }
    }

    func stop() {
        setupTask?.cancel()
        setupTask = nil
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
            await self?.checkForGitDirectoryChange()
        }
    }

    private func checkForGitDirectoryChange() async {
        guard let projectURL, let watchedGitDirectory else { return }

        let gitDirectory = URL(fileURLWithPath: watchedGitDirectory, isDirectory: true)
        let currentSnapshot = await Task.detached(priority: .utility) {
            GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)
        }.value
        let previousSnapshot = lastSnapshot
        let headChanged = currentSnapshot.head != previousSnapshot?.head
        let indexChanged = currentSnapshot.index != previousSnapshot?.index
        let stashChanged = currentSnapshot.stash != previousSnapshot?.stash
        let refsChanged = currentSnapshot.refs != previousSnapshot?.refs

        guard headChanged || indexChanged || stashChanged || refsChanged else { return }

        lastSnapshot = currentSnapshot

        onChange(
            GitOKGitDirectoryChange(
                projectURL: projectURL,
                gitDirectoryPath: watchedGitDirectory,
                changeKind: changeKind(
                    headChanged: headChanged,
                    indexChanged: indexChanged,
                    stashChanged: stashChanged,
                    refsChanged: refsChanged
                ),
                headChanged: headChanged,
                indexChanged: indexChanged,
                stashChanged: stashChanged,
                refsChanged: refsChanged,
                previousHead: previousSnapshot?.head,
                head: currentSnapshot.head
            )
        )
    }

    nonisolated static func changeKind(headChanged: Bool, indexChanged: Bool, stashChanged: Bool, refsChanged: Bool) -> String {
        let changes = [
            headChanged ? "head" : nil,
            indexChanged ? "index" : nil,
            stashChanged ? "stash" : nil,
            refsChanged ? "refs" : nil
        ].compactMap { $0 }

        return changes.count == 1 ? changes[0] : "multiple"
    }

    private func changeKind(headChanged: Bool, indexChanged: Bool, stashChanged: Bool, refsChanged: Bool) -> String {
        Self.changeKind(
            headChanged: headChanged,
            indexChanged: indexChanged,
            stashChanged: stashChanged,
            refsChanged: refsChanged
        )
    }
}
