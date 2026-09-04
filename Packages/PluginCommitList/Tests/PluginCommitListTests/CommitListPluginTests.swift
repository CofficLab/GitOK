import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderRailView
import ProviderRootView
import SwiftUI
import XCTest
@testable import PluginCommitList
@testable import ProviderRootView

@MainActor
final class CommitListPluginTests: XCTestCase {
    /// 最小 ProjectProviding mock：空项目列表。
    private final class MockProjects: ProjectProviding {
        var projects: [Project] = []
        var currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?
        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle { MockHandle() }
        func openProject(at url: URL) {}
        func closeCurrentProject() {}
        func addProject(at url: URL) {}
        func removeProject(id: UUID) {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func persist() {}
        func selectCommit(_ commit: GitCommit) { currentCommit = commit }
        func selectFile(_ path: String?) { currentFile = path }
        func clearCommitSelection() {
            currentCommit = nil
            currentFile = nil
            currentCommitFiles = nil
        }
        func notifyDataChanged() {}
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }

    private func makeKernel() throws -> (
        kernel: KernelCoreContainer,
        rail: DefaultRailViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let rail = DefaultRailViewProviding()
        try kernel.registerProvider((any RailViewProviding).self, rail)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        return (kernel, rail)
    }

    func testOnBootAddsRailSection() throws {
        let (kernel, rail) = try makeKernel()
        let plugin = CommitListPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(rail.sections.contains { $0.id == "\(plugin.id).section" })
    }

    func testOnShutdownRemovesRailSection() throws {
        let (kernel, rail) = try makeKernel()
        let plugin = CommitListPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
        XCTAssertFalse(rail.sections.contains { $0.id == "\(plugin.id).section" })
    }

    func testOnBootSkipsWhenProjectsMissing() throws {
        let kernel = KernelCoreContainer()
        let rail = DefaultRailViewProviding()
        try kernel.registerProvider((any RailViewProviding).self, rail)
        // 不注册 ProjectProviding。
        try CommitListPlugin().onBoot(kernel: kernel)
        XCTAssertTrue(rail.sections.isEmpty, "no rail section when ProjectProviding is missing")
    }
}
