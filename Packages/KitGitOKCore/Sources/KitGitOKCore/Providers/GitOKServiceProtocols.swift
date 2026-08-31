import KernelCore
import ProviderGit
import ProviderNavigation
import ProviderTheme

// MARK: - Required Services

/// Service types the app shell must register before plugins become ready.
///
/// Mirrors the kernel validation contract of a factory host: startup fails
/// loudly, listing exactly what is missing, instead of failing later with
/// cryptic `resolve()` nils scattered across plugin views.
public enum GitOKRequiredServices {
    public static let all: [Any.Type] = [
        GitOKRepositoryServicing.self,
        GitOKActivityServicing.self,
        GitOKGitCommandServicing.self,
        GitOKThemeServicing.self,
        GitOKNavigationServicing.self,
    ]

    @MainActor
    public static func missing(in dependencies: GitOKPluginDependencies) -> [String] {
        all.compactMap { service in
            dependencies.resolveAny(service) == nil ? String(describing: service) : nil
        }
    }

    @MainActor
    public static func missing(in kernel: KernelCoreContainer) -> [String] {
        all.compactMap { service in
            kernel.resolveProviderErased(service) == nil ? String(describing: service) : nil
        }
    }
}
