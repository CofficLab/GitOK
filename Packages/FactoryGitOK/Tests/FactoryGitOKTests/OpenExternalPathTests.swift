import KernelCore
import KitGit
import ProviderProjects
import XCTest
@testable import FactoryGitOK

/// `FactoryGitOK.openExternalPath` 的行为测试。
///
/// 该入口承载 CLI 脚本 `gitok <path>` 的核心语义：把外部目录加入项目列表
/// 并切换为当前项目。
@MainActor
final class OpenExternalPathTests: XCTestCase {

    /// 记录调用轨迹的 `ProjectProviding` 桩实现。
    private final class RecordingProjects: ProjectProviding {
        var projects: [Project] = []
        var currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?
        /// 收到过的 `openProject(at:)` 路径。
        private(set) var openedPaths: [String] = []

        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle { NoopHandle() }

        func openProject(at url: URL) {
            openedPaths.append(url.standardizedFileURL.path)
        }

        func closeCurrentProject() {}
        func addProject(at url: URL) {}
        func removeProject(id: UUID) {}
        func renameProject(id: UUID, newName: String) throws {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func persist() {}
        func selectCommit(_ commit: GitCommit) {}
        func selectFile(_ path: String?) {}
        func clearCommitSelection() {}
        func notifyDataChanged() {}
    }

    private final class NoopHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }

    private func makeKernel(with projects: RecordingProjects) throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any ProjectProviding).self, projects)
        return kernel
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-open-external-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testOpenExternalPathOpensExistingDirectory() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let projects = RecordingProjects()
        let kernel = try makeKernel(with: projects)

        XCTAssertTrue(FactoryGitOK.openExternalPath(directory.path, kernel: kernel))
        XCTAssertEqual(projects.openedPaths.count, 1)
        XCTAssertEqual(
            projects.openedPaths.first,
            URL(fileURLWithPath: directory.path).resolvingSymlinksInPath().standardizedFileURL.path
        )
    }

    func testOpenExternalPathRejectsMissingDirectory() throws {
        let projects = RecordingProjects()
        let kernel = try makeKernel(with: projects)

        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-missing-\(UUID().uuidString)", isDirectory: true)
        XCTAssertFalse(FactoryGitOK.openExternalPath(missing.path, kernel: kernel))
        XCTAssertTrue(projects.openedPaths.isEmpty)
    }

    func testOpenExternalPathRejectsFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("not-a-directory.txt")
        try Data("x".utf8).write(to: file)

        let projects = RecordingProjects()
        let kernel = try makeKernel(with: projects)

        XCTAssertFalse(FactoryGitOK.openExternalPath(file.path, kernel: kernel))
        XCTAssertTrue(projects.openedPaths.isEmpty)
    }

    func testOpenExternalPathWithoutProjectsProviderReturnsFalse() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let kernel = KernelCoreContainer()
        XCTAssertFalse(FactoryGitOK.openExternalPath(directory.path, kernel: kernel))
    }
}
