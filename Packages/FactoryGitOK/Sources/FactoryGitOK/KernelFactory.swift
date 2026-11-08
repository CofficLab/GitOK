import Foundation
import KernelCore
import ProviderProjects
import ProviderSettingView
import SwiftUI

/// KernelFactory — 内核工厂。
///
/// 负责创建 KernelCore 内核，内部通过 `DefaultProviderFactory` 装配
/// GitOK 所需的 Provider，并通过 `start(plugins:)` 启动专用插件目录。
///
/// 视图组装（主视图 / 设置视图 / LumiUI 主题桥接）由 `ViewFactory` 完成；
/// `KernelFactory` 的便捷入口委托 `DefaultViewFactory`，宿主可通过
/// `makeMainView(kernel:viewFactory:)` / `makeSettingsView(kernel:viewFactory:)`
/// 传入自定义 `ViewFactory` 覆盖视图组装逻辑。
@MainActor
public enum KernelFactory {
    /// 创建 KernelCore 内核，装配并注册 GitOK 所需 Provider。
    ///
    /// - Returns: 已装配默认 Provider 的 KernelCore 容器。
    /// - Throws: `KernelCoreError.providerAlreadyRegistered` — 同类型重复注册时。
    public static func makeKernel(
        additionalPlugins: [any SuperPlugin] = []
    ) throws -> KernelCoreContainer {
        try makeKernel(
            providerFactory: DefaultProviderFactory(),
            pluginFactory: DefaultPluginFactory(),
            additionalPlugins: additionalPlugins
        )
    }

    /// 使用宿主提供的 Provider / Plugin 工厂装配内核。
    ///
    /// Provider 的创建与注册全部委托给 `providerFactory.registerProviders(into:)`；
    /// 本方法只负责创建容器、启动插件并完成插件启动后的视图绑定。
    public static func makeKernel(
        providerFactory: any ProviderFactory,
        pluginFactory: any PluginFactory,
        additionalPlugins: [any SuperPlugin] = []
    ) throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try providerFactory.registerProviders(into: kernel)

        // 默认目录与宿主附加插件在同一个依赖图中统一校验、排序、原子启动。
        // 后续复刻插件只需由 App/专用 Factory 传入，不必继续修改内核工厂。
        try kernel.start(plugins: pluginFactory.makePlugins() + additionalPlugins)
        resetSettingsSelectionToFirstEntry(in: kernel)

        return kernel
    }

    /// 设置窗口默认选中 order 最小的入口（回归修复）。
    ///
    /// `addEntries` 会走 `registerEntries`，其"选中为空则锁定为当时列表第一个"
    /// 的语义会让**最先注册入口的插件**意外成为默认选中（如 projects），
    /// 与"默认选中第一个（通用）"的设计意图相悖。全部入口就位后在此重置；
    /// 本次运行内的用户选择不受影响（选中态在内存中保留，重启后回到第一个）。
    private static func resetSettingsSelectionToFirstEntry(in kernel: KernelCoreContainer) {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self),
              let firstID = settings.entries.first?.id,
              settings.selectedEntryID != firstID
        else { return }
        settings.selectEntry(id: firstID)
    }

    // MARK: - External Open

    /// 打开外部传入的目录：加入项目列表并切换为当前项目。
    ///
    /// CLI 脚本 `gitok <path>` / Finder「在 GitOK 中打开」都走这条路径。
    /// `ProjectProviding.openProject(at:)` 的语义已覆盖需求：目录不在列表中
    /// 时会插入列表，已存在时只更新最近打开时间，两者都会把该目录设为
    /// 当前项目。
    ///
    /// - Parameters:
    ///   - path: 目录路径（可含 `~`）。
    ///   - kernel: 已装配的内核。
    /// - Returns: 目录有效且已成功切换当前项目时为 `true`。
    @discardableResult
    public static func openExternalPath(
        _ path: String,
        kernel: KernelCoreContainer
    ) -> Bool {
        let normalizedPath = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
        guard !normalizedPath.isEmpty,
              FileManager.default.fileExists(atPath: normalizedPath) else {
            return false
        }

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory)
        guard isDirectory.boolValue else { return false }

        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            return false
        }
        projects.openProject(at: URL(fileURLWithPath: normalizedPath))
        return true
    }

    // MARK: - Main View Assembly

    /// 创建内核并组装完整主视图（工具栏 + 侧边栏 + Rail + 内容区）。
    ///
    /// 视图组装逻辑由 `ViewFactory` 完成（默认 `DefaultViewFactory`）；
    /// 宿主只需要一个视图，无需关心内核如何把各 Provider 的能力组合起来。
    public static func makeMainView() throws -> AnyView {
        try makeMainView(kernel: makeKernel())
    }

    /// 使用已装配的内核组装主视图（共享内核时使用）。
    public static func makeMainView(kernel: KernelCoreContainer) throws -> AnyView {
        try makeMainView(kernel: kernel, viewFactory: DefaultViewFactory())
    }

    /// 使用自定义 `ViewFactory` 组装主视图（覆盖视图组装逻辑时使用）。
    public static func makeMainView(
        kernel: KernelCoreContainer,
        viewFactory: any ViewFactory
    ) throws -> AnyView {
        try viewFactory.makeMainView(kernel: kernel)
    }

    // MARK: - Settings View Assembly

    /// 创建内核并返回设置视图。
    public static func makeSettingsView() throws -> AnyView {
        try makeSettingsView(kernel: makeKernel())
    }

    /// 使用已装配的内核返回设置视图（共享内核时使用）。
    public static func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
        try makeSettingsView(kernel: kernel, viewFactory: DefaultViewFactory())
    }

    /// 使用自定义 `ViewFactory` 组装设置视图（覆盖视图组装逻辑时使用）。
    public static func makeSettingsView(
        kernel: KernelCoreContainer,
        viewFactory: any ViewFactory
    ) throws -> AnyView {
        try viewFactory.makeSettingsView(kernel: kernel)
    }
}
