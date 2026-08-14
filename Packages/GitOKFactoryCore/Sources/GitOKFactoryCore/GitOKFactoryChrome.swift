import SwiftUI

/// Composition hooks for the factory host engine.
///
/// The layout in `GitOKFactoryCore` is plugin-agnostic; the composition root
/// (app shell) injects shell-owned chrome through these hooks at startup,
/// mirroring how a Lumi factory host receives concrete contributions from
/// the outside instead of depending on feature plugins.
@MainActor
public enum GitOKFactoryChrome {
    /// Toolbar item rendered in the sidebar column (e.g. the add-project button).
    public static var sidebarToolbarItem: AnyView?
}
