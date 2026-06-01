import GitOKCoreKit

public enum SubmodulePresentation {
    public static func issueCount(_ submodules: [GitRepositoryCLI.GitSubmodule]) -> Int {
        submodules.filter { $0.status != .initialized }.count
    }

    public static func iconName(issueCount: Int) -> String {
        issueCount > 0 ? "shippingbox.fill" : "shippingbox"
    }

    public static func statusText(for status: GitRepositoryCLI.GitSubmodule.Status) -> String {
        switch status {
        case .initialized:
            return PluginSubmoduleLocalization.string("Initialized")
        case .uninitialized:
            return PluginSubmoduleLocalization.string("Uninitialized")
        case .modified:
            return PluginSubmoduleLocalization.string("HEAD differs from index")
        case .conflicted:
            return PluginSubmoduleLocalization.string("Conflicted")
        }
    }

    public static func statusIcon(for status: GitRepositoryCLI.GitSubmodule.Status) -> String {
        switch status {
        case .initialized:
            return "checkmark.circle"
        case .uninitialized:
            return "tray.and.arrow.down"
        case .modified:
            return "arrow.triangle.2.circlepath"
        case .conflicted:
            return "exclamationmark.triangle"
        }
    }

    public static func rowSubtitle(for submodule: GitRepositoryCLI.GitSubmodule) -> String {
        let shortHash = String(submodule.commitHash.prefix(8))
        let description = submodule.description.map { " · \($0)" } ?? ""
        return "\(statusText(for: submodule.status)) · \(shortHash)\(description)"
    }
}
