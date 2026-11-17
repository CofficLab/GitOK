import Foundation

/// 推送失败的类别，决定是否值得重试或回退到系统 Git。
public enum GitPushFailureKind: Sendable {
    /// 传输层故障（SSL/TLS、DNS、连接超时等），重试或换一种传输方式可能成功。
    case transient
    /// 认证失败，重试无意义，但系统 Git 的凭据助手可能持有可用凭据。
    case authentication
    /// 业务失败（non-fast-forward、无 upstream、hook 拒绝等），换执行引擎结果相同。
    case permanent
}

public struct GitPushRetryPolicy: Sendable, Equatable {
    /// 包含首次尝试在内的总尝试次数。
    public var maximumAttempts: Int
    public var initialDelay: TimeInterval
    public var delayMultiplier: Double
    public var maximumDelay: TimeInterval

    public init(
        maximumAttempts: Int = 3,
        initialDelay: TimeInterval = 2,
        delayMultiplier: Double = 2,
        maximumDelay: TimeInterval = 8
    ) {
        self.maximumAttempts = maximumAttempts
        self.initialDelay = initialDelay
        self.delayMultiplier = delayMultiplier
        self.maximumDelay = maximumDelay
    }
}

/// 重试与回退全部失败后的错误，保留最后一次主引擎与回退引擎的报错，
/// 调用方可以在此基础上补充面向用户的处置建议。
public struct GitPushRecoveryError: Error, LocalizedError, Sendable {
    public let kind: GitPushFailureKind
    public let primaryMessage: String
    public let fallbackMessage: String?

    public init(kind: GitPushFailureKind, primaryMessage: String, fallbackMessage: String?) {
        self.kind = kind
        self.primaryMessage = primaryMessage
        self.fallbackMessage = fallbackMessage
    }

    public var errorDescription: String? {
        primaryMessage
    }
}

/// 推送恢复策略：传输类错误按指数退避重试，认证类错误直接回退，
/// 业务错误立即抛出。回退引擎只在调用方提供时才会执行。
public enum GitPushRecovery {
    public static func perform(
        policy: GitPushRetryPolicy = GitPushRetryPolicy(),
        classification: (Error) -> GitPushFailureKind,
        primary: () throws -> Void,
        fallback: (() throws -> Void)? = nil,
        sleep: (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    ) throws {
        var attempt = 1
        var delay = policy.initialDelay

        while true {
            do {
                try primary()
                return
            } catch {
                let kind = classification(error)
                switch kind {
                case .permanent:
                    throw error
                case .authentication:
                    try runFallback(kind: kind, primaryError: error, fallback: fallback)
                    return
                case .transient:
                    guard attempt < policy.maximumAttempts else {
                        try runFallback(kind: kind, primaryError: error, fallback: fallback)
                        return
                    }
                    sleep(delay)
                    attempt += 1
                    delay = min(delay * policy.delayMultiplier, policy.maximumDelay)
                }
            }
        }
    }

    private static func runFallback(
        kind: GitPushFailureKind,
        primaryError: Error,
        fallback: (() throws -> Void)?
    ) throws {
        guard let fallback else {
            throw GitPushRecoveryError(
                kind: kind,
                primaryMessage: primaryError.localizedDescription,
                fallbackMessage: nil
            )
        }

        do {
            try fallback()
        } catch {
            throw GitPushRecoveryError(
                kind: kind,
                primaryMessage: primaryError.localizedDescription,
                fallbackMessage: error.localizedDescription
            )
        }
    }
}
