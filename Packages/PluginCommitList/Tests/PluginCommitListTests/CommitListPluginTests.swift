import Foundation
import KernelCore
import ProviderCommit
import ProviderProjects
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
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }

    private func makeKernel(withDetail: Bool) throws -> (
        kernel: KernelCoreContainer,
        root: DefaultRootViewProvider
    ) {
        let kernel = KernelCoreContainer()
        let root = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, root)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        if withDetail {
            try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        }
        return (kernel, root)
    }

    func testOnBootInjectsRailView() throws {
        let (kernel, root) = try makeKernel(withDetail: true)
        try CommitListPlugin().onBoot(kernel: kernel)
        XCTAssertNotNil(root.railView, "rail view should be injected on boot")
    }

    func testOnShutdownClearsRailView() throws {
        let (kernel, root) = try makeKernel(withDetail: true)
        let plugin = CommitListPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
        XCTAssertNil(root.railView)
    }

    func testOnBootSkipsWhenCommitDetailMissing() throws {
        let (kernel, root) = try makeKernel(withDetail: false)
        try CommitListPlugin().onBoot(kernel: kernel)
        XCTAssertNil(root.railView, "no rail injection when CommitDetailProviding is missing")
    }
}
