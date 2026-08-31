import SwiftUI

/// Composition hooks for the factory host engine.
///
/// The layout in `FactoryCore` is plugin-agnostic; the composition root
/// (app shell) injects shell-owned chrome through these hooks at startup,
/// mirroring how a Lumi factory host receives concrete contributions from
/// the outside instead of depending on feature plugins.
@MainActor
public enum GitOKFactoryChrome {
    /// Toolbar item rendered in the sidebar column (e.g. the add-project button).
    public static var sidebarToolbarItem: AnyView?

    /// One-shot launch hooks run from `applicationDidFinishLaunching`.
    ///
    /// Channel-specific work that cannot live in the plugin-agnostic host
    /// (e.g. starting the Sparkle updater) is registered here by the app
    /// entry point, mirroring how Lumi injects `AppUpdatePlugin` at the
    /// `LumiApp` layer.
    public static var launchHooks: [@MainActor () -> Void] = []
}
