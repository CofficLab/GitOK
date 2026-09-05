import KernelCore
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

        return kernel
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
