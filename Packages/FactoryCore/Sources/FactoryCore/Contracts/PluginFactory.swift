import KitGitOKCore

/// Lumi-shaped plugin composition boundary.
///
/// Concrete plugin packages are visible only to the composition target that
/// implements this protocol (`FactoryGitOK`).
@MainActor
public protocol PluginFactory {
    func makeComposition() -> RootContainer.Composition
}
