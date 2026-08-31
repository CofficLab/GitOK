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
        AnyView(ContentLayout().inRootView(kernel: kernel))
    }

    public func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
        AnyView(SettingsSceneContent(kernel: kernel))
    }
}
