import GitOKFactoryCore
import SwiftUI

/// Factory composition facade (Lumi `FactoryLumi` equivalent).
///
/// Owns the compile-time plugin catalog and hands it to the plugin-agnostic
/// host engine in `GitOKFactoryCore`. The app entry point stays minimal:
/// `GitOKApp` only calls `makeMainWindow()` / `makeCommands()` /
/// `makeSettingsWindow()` here.
public enum GitOKFactory {
    /// Composition inputs for the bundled GitOK plugin catalog.
    @MainActor
    private static func makeComposition() -> RootContainer.Composition {
        RootContainer.Composition(
            plugins: GeneratedPluginRegistry.plugins,
            configurePluginRuntimes: { projectService in
                GitOKPluginBootstrap.configureRuntimes(projectService: projectService)
            },
            sidebarToolbarItem: AnyView(BtnAdd())
        )
    }

    /// Main window content with the full plugin composition installed.
    @MainActor
    public static func makeMainWindow() -> some View {
        RootContainer.configure(makeComposition())
        return ContentLayout()
            .inRootView()
            .settingsWindowOpener(appVM: RootContainer.shared.appVM)
    }

    /// macOS menu commands contributed by the app.
    public static func makeCommands() -> some Commands {
        GitOKAppCommands()
    }

    /// Settings window content.
    @MainActor
    public static func makeSettingsWindow() -> some View {
        SettingsSceneContent()
    }
}

/// Aggregates the app's menu command groups.
public struct GitOKAppCommands: Commands {
    public init() {}

    public var body: some Commands {
        DebugCommand()
        ConfigCommand()
        GitCommand()
        SettingsCommand()
    }
}
