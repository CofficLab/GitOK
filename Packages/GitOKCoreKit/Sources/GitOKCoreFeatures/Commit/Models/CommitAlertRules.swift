import Foundation

public enum CommitAlertRules {
    public static func errorMessage(from error: Error) -> String {
        error.localizedDescription
    }

    public static func performError(
        _ error: Error,
        showError: (String) -> Void
    ) {
        showError(errorMessage(from: error))
    }

    public static func performMessage(
        _ message: String,
        showError: (String) -> Void
    ) {
        showError(message)
    }

    public static func performInfo(
        _ message: String,
        showInfo: (String) -> Void
    ) {
        showInfo(message)
    }
}
