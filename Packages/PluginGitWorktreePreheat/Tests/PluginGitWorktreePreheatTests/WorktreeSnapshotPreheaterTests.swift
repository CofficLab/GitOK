import Foundation
import KitGit
import ProviderProjects
import Testing
@testable import PluginGitWorktreePreheat

@Suite("WorktreeSnapshotPreheater")
@MainActor
struct WorktreeSnapshotPreheaterTests {
    @Test("启动后预热项目列表中的全部有效目录")
    func startsBackgroundLoadsForAllProjects() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-(UUID().uuidString)", isDirectory: true)
        let projectA = root.appendingPathComponent("A", isDirectory: true)
        let projectB = root.appendingPathComponent("B", isDirectory: true)
        try FileManager.default.createDirectory(at: projectA, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: projectB, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = MockProjects(
            projects: [
                Project(url: projectA),
                Project(url: projectB),
            ],
            currentProject: Project(url: projectA)
        )

        let recorder = LoadRecorder()
        let preheater = WorktreeSnapshotPreheater(
            projects: projects,
            loadSnapshot: { url, _ in recorder.append(url) },
            invalidateSnapshot: { _ in },
            gitWatch: nil
        )
        preheater.start()
        defer { preheater.stop() }

        for _ in 0..<100 where recorder.urls.count < 2 {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(Set(recorder.urls) == Set([projectA.standardizedFileURL, projectB.standardizedFileURL]))
        #expect(recorder.urls.first == projectA.standardizedFileURL)
    }

    private final class LoadRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [URL] = []

        var urls: [URL] {
            lock.lock()
            defer { lock.unlock() }
            return values
        }

        func append(_ url: URL) {
            lock.lock()
            values.append(url.standardizedFileURL)
            lock.unlock()
        }
    }

    private final class MockProjects: ProjectProviding {
        let projects: [Project]
        let currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?

        init(projects: [Project], currentProject: Project?) {
            self.projects = projects
            self.currentProject = currentProject
        }

        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle {
            MockHandle()
        }

        func openProject(at url: URL) {}
        func closeCurrentProject() {}
        func addProject(at url: URL) {}
        func removeProject(id: UUID) {}
        func renameProject(id: UUID, newName: String) throws {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func notifyDataChanged() {}
        func persist() {}
        func selectCommit(_ commit: GitCommit) {}
        func selectFile(_ path: String?) {}
        func clearCommitSelection() {}
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }
}
