import Foundation
import KitGit
import LibGit2Swift

enum LibGit2PushFailureClassifier {
    static func classify(_ error: Error) -> GitPushFailureKind {
        guard let error = error as? LibGit2Error else { return .permanent }

        switch error {
        case .networkError:
            return .transient
        case .authenticationError:
            return .authentication
        case .pushFailed(let message):
            return isTransportFailure(message) ? .transient : .permanent
        default:
            return .permanent
        }
    }

    static func isTransportFailure(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return transportKeywords.contains { lowercased.contains($0) }
    }

    private static let transportKeywords = [
        "securetransport", "ssl", "tls", "certificate",
        "-9806", "-9814", "-9802", "-9843",
        "could not resolve host", "failed to connect", "connection timed out",
        "connection refused", "network is unreachable", "no route to host",
        "operation timed out", "connection reset", "broken pipe",
        "couldn't connect", "couldn't resolve", "name resolution",
        "unable to access", "failed to send request", "early eof",
        "gnutls", "libcurl", "proxy", "tunnel", "socket",
    ]
}

enum SystemGitPushCommand {
    static func branchArguments() -> [String] {
        ["push"]
    }

    static func tagArguments(named name: String, remote: String) -> [String] {
        ["push", remote, "refs/tags/\(name):refs/tags/\(name)"]
    }

    /// 回退过程没有终端，必须让 git 直接失败而不是等待凭据输入。
    static let environment = ["GIT_TERMINAL_PROMPT": "0"]
}

enum LibGit2PushRecovery {
    static func push(
        in repository: URL,
        policy: GitPushRetryPolicy = GitPushRetryPolicy(),
        primary: () throws -> Void
    ) throws {
        try perform(
            in: repository,
            arguments: SystemGitPushCommand.branchArguments(),
            policy: policy,
            primary: primary
        )
    }

    static func pushTag(
        named name: String,
        remote: String,
        in repository: URL,
        policy: GitPushRetryPolicy = GitPushRetryPolicy(),
        primary: () throws -> Void
    ) throws {
        try perform(
            in: repository,
            arguments: SystemGitPushCommand.tagArguments(named: name, remote: remote),
            policy: policy,
            primary: primary
        )
    }

    static func perform(
        in repository: URL,
        arguments: [String],
        policy: GitPushRetryPolicy = GitPushRetryPolicy(),
        primary: () throws -> Void
    ) throws {
        do {
            try GitPushRecovery.perform(
                policy: policy,
                classification: LibGit2PushFailureClassifier.classify,
                primary: primary,
                fallback: systemGitFallback(arguments: arguments, in: repository)
            )
        } catch let error as GitPushRecoveryError {
            throw PushRecoveryFailure(recovery: error)
        }
    }

    private static func systemGitFallback(
        arguments: [String],
        in repository: URL
    ) -> (() throws -> Void)? {
        guard GitProcessRunner.isAvailable else { return nil }
        return {
            _ = try GitProcessRunner.run(
                arguments,
                in: repository,
                environment: SystemGitPushCommand.environment
            )
        }
    }
}

struct PushRecoveryFailure: Error, LocalizedError, Sendable {
    let recovery: GitPushRecoveryError

    var errorDescription: String? {
        let hint = pluginLocalization.string(
            "Check your credentials, proxy or VPN settings, or switch the remote to SSH, then try again."
        )
        return "\(hint)\n\(recovery.primaryMessage)"
    }
}
