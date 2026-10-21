import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderProjects
import ProviderToolbar
import XCTest
@testable import KitOpenIn

/// `OpenInPluginBase` 的接线覆盖。
///
/// 基类负责把「打开目标」装配成工具栏按钮：id / metadata / order 由 target 派生，
/// onBoot 需要工具栏与项目两个依赖，未安装的目标不占工具栏位（Remote 恒可用）。
@MainActor
final class OpenInPluginBaseTests: XCTestCase {

    /// 测试用子类：只继承基类默认实现。
    private final class TestOpenPlugin: OpenInPluginBase {
        override init(target: OpenTarget) {
            super.init(target: target)
        }
    }

    private func makeKernel(
        withToolbar: Bool = true,
        withProjects: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        toolbar: DefaultToolbarProviding,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        let docs = DefaultDocsViewProviding()
        if withToolbar {
            try kernel.registerProvider((any ToolbarProviding).self, toolbar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, OpenInProjectsStub())
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, toolbar, docs)
    }

    // MARK: - 身份派生

    func testIdentityIsDerivedFromTarget() {
        let plugin = TestOpenPlugin(target: .vscode)
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.open-vscode")
        XCTAssertEqual(plugin.order, OpenTarget.vscode.toolbarOrder)
        XCTAssertEqual(plugin.metadata.id, plugin.id)
        XCTAssertEqual(plugin.metadata.name, "Open VS Code")
        XCTAssertEqual(plugin.metadata.category, .project)
        XCTAssertEqual(plugin.metadata.stage, .stable)
        XCTAssertEqual(plugin.metadata.policy, .disabled)
    }

    // MARK: - 守卫链

    func testOnBootWithoutToolbarRegistersNothing() throws {
        let (kernel, _, _) = try makeKernel(withToolbar: false)
        let plugin = TestOpenPlugin(target: .remote)

        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(kernel.resolveProvider((any ToolbarProviding).self) == nil)
    }

    func testOnBootWithoutProjectsRegistersNothing() throws {
        let (kernel, toolbar, _) = try makeKernel(withProjects: false)
        let plugin = TestOpenPlugin(target: .remote)

        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    // MARK: - 工具栏项

    func testOnBootRegistersToolbarItemForAlwaysAvailableTarget() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = TestOpenPlugin(target: .remote)

        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(toolbar.toolbarItems.count, 1)
        let item = try XCTUnwrap(toolbar.toolbarItems.first)
        XCTAssertEqual(item.id, "\(plugin.id).button")
        XCTAssertEqual(item.placement, .trailing)
        XCTAssertEqual(item.category, .project)
        XCTAssertEqual(item.order, OpenTarget.remote.toolbarOrder)
    }

    /// 未安装的目标不占工具栏位：是否注册完全取决于本机是否装了对应应用。
    func testToolbarItemIsOnlyRegisteredForInstalledTargets() throws {
        for target in OpenTarget.allCases {
            let (kernel, toolbar, _) = try makeKernel()
            let plugin = TestOpenPlugin(target: target)

            try plugin.onBoot(kernel: kernel)

            let expected = target.isAlwaysAvailable || AppLauncher.isInstalled(target)
            XCTAssertEqual(
                toolbar.toolbarItems.isEmpty == false,
                expected,
                "target \(target.rawValue) 的工具栏项注册与安装状态不一致"
            )
        }
    }

    func testOnShutdownRemovesToolbarItem() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = TestOpenPlugin(target: .remote)
        try plugin.onBoot(kernel: kernel)
        XCTAssertFalse(toolbar.toolbarItems.isEmpty)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    func testOnShutdownWithoutBootIsSafe() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = TestOpenPlugin(target: .remote)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterAddsAboutEntryAndOnUnregisterRemovesIt() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = TestOpenPlugin(target: .kiro)

        try plugin.onRegister(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testOnRegisterWithoutDocsProviderIsSafe() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = TestOpenPlugin(target: .kiro)

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    /// 策略为 .disabled 的插件不会被 kernel.start 注册。
    func testStartViaKernelSkipsDisabledPolicy() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = TestOpenPlugin(target: .remote)

        try kernel.start(plugins: [plugin])

        XCTAssertFalse(kernel.isPluginRegistered(id: plugin.id))
        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }
}

/// `ProjectProviding` 的最小替身。
@MainActor
final class OpenInProjectsStub: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        OpenInProjectsHandle()
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ file: String?) {}
    func clearCommitSelection() {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
final class OpenInProjectsHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
