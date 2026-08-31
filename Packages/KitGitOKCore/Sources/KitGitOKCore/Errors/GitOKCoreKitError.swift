import Foundation

/// Kernel-level errors for the plugin runtime.
public enum KitGitOKCoreError: Error, LocalizedError, Sendable {
    /// Startup validation failed because required services were not registered.
    case missingRequiredServices([String])

    public var errorDescription: String? {
        switch self {
        case .missingRequiredServices(let names):
            "Plugin startup failed; missing required services: \(names.joined(separator: ", "))"
        }
    }
}
