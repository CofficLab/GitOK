import Foundation

enum ShellError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output):
            return "Command failed with output: \(output)"
        }
    }
}
