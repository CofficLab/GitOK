import FactoryCore
import KernelCore
import SwiftUI

/// Factory composition facade (Lumi `FactoryLumi` equivalent).
///
/// Owns the compile-time plugin catalog and hands it to the plugin-agnostic
/// host engine in `FactoryCore`. The app entry point stays minimal:
/// `GitOKApp` assembles one Kernel and passes it to the window and command
/// factories here.
public struct GitOKFactory: PluginFactory {
    public init() {}

    /// Composition inputs for the bundled GitOK plugin catalog.
    @MainActor
    public func makeComposition() -> RootContainer.Composition {
        RootContainer.Composition(
            plugins: GeneratedPluginRegistry.plugins,
            configurePluginRuntimes: { projectService in
                GitOKPluginBootstrap.configureRuntimes(projectService: projectService)
            },
            sidebarToolbarItem: AnyView(BtnAdd())
        )
    }

    @MainActor
    public static func makeKernel() throws -> KernelCoreContainer {
        try KernelFactory.makeKernel(pluginFactory: GitOKFactory())
    }

    @MainActor
    public static func makeMainWindow(kernel: KernelCoreContainer) throws -> AnyView {
        let view = try KernelFactory.makeMainView(kernel: kernel)
        guard let appVM = kernel.resolveProvider(AppVM.self) else {
            return view
        }
        return AnyView(view.settingsWindowOpener(appVM: appVM))
    }

    /// macOS menu commands contributed by the app.
    public static func makeCommands(kernel: KernelCoreContainer) -> some Commands {
        GitOKAppCommands(kernel: kernel)
    }

    /// Settings window content.
    @MainActor
    public static func makeSettingsWindow(kernel: KernelCoreContainer) throws -> AnyView {
        try KernelFactory.makeSettingsView(kernel: kernel)
    }
}

/// Aggregates the app's menu command groups.
public struct GitOKAppCommands: Commands {
    private let kernel: KernelCoreContainer

    public init(kernel: KernelCoreContainer) {
        self.kernel = kernel
    }

    public var body: some Commands {
        DebugCommand()
        ConfigCommand(kernel: kernel)
        GitCommand(kernel: kernel)
        SettingsCommand()
    }
}
