import KitGitOKCore
import KernelCore
import SwiftUI

/// Kernel composition entry point, matching Lumi's `KernelFactory` role.
@MainActor
public enum KernelFactory {
    public static func makeKernel(
        pluginFactory: any PluginFactory,
        providerFactory: (any ProviderFactory)? = nil
    ) throws -> KernelCoreContainer {
        let factory = providerFactory ?? DefaultProviderFactory()
        let kernel = KernelCoreContainer()
        let root = try factory.makeRootContainer(
            kernel: kernel,
            composition: pluginFactory.makeComposition()
        )
        if let pluginService = kernel.resolveProvider(PluginService.self) {
            try kernel.start(plugins: [GitOKPluginKernelAdapter(pluginService: pluginService)])
        } else {
            try kernel.start()
        }
        return root.kernel
    }

    public static func makeMainView(
        kernel: KernelCoreContainer,
        viewFactory: (any ViewFactory)? = nil
    ) throws -> AnyView {
        try (viewFactory ?? DefaultViewFactory()).makeMainView(kernel: kernel)
    }

    public static func makeSettingsView(
        kernel: KernelCoreContainer,
        viewFactory: (any ViewFactory)? = nil
    ) throws -> AnyView {
        try (viewFactory ?? DefaultViewFactory()).makeSettingsView(kernel: kernel)
    }
}

@MainActor
public struct DefaultViewFactory: ViewFactory {
    public init() {}

    public func makeMainView(kernel: KernelCoreContainer) throws -> AnyView {
        // 分散 provider 装配（对齐 Lumi 的 RootViewProviding / ToolbarProviding）：
        // 根布局 provider 持有工具栏与内容视图，宿主注入后由 makeRootView() 组合。
        let rootProvider = kernel.resolveProvider((any GitOKRootViewProviding).self)
            ?? DefaultGitOKRootViewProvider()
        let toolbarProvider = kernel.resolveProvider((any GitOKToolbarProviding).self)
            ?? DefaultGitOKToolbarProvider()

        // 工具栏视图由 toolbar provider 渲染并注入根布局。
        rootProvider.setToolbarView(toolbarProvider.makeToolbarView())

        // 内容视图（ContentView 只负责内容区，顶栏已上移至 provider）。
        rootProvider.setContentView(AnyView(ContentLayout()))

        // 根布局 = VStack{ 工具栏; 内容 }.ignoresSafeArea()
        let root = rootProvider.makeRootView()
            // 让 ContentView 等子视图能通过环境对象访问 toolbar provider。
            .environmentObject(toolbarProvider)

        return AnyView(root.inRootView(kernel: kernel))
    }

    public func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
        AnyView(SettingsSceneContent(kernel: kernel))
    }
}
