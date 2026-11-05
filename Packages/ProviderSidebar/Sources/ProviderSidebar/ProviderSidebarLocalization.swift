import Foundation
import KitGitOKLocalization

/// Runtime localization for this plugin bundle.
///
/// English strings are the localization keys and the default fallback.
enum ProviderSidebarLocalization {
    static func string(_ key: String) -> String {
        GitOKLocalization.string(key, bundle: .module)
    }
}
