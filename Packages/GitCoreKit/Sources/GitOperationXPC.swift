import Foundation

@objc public protocol GitOperationXPCProtocol {
    func mergeBranches(
        repositoryPath: String,
        sourceBranch: String,
        targetBranch: String,
        withReply reply: @escaping (NSDictionary) -> Void
    )
}

public enum GitOperationHelperError: LocalizedError {
    case connectionUnavailable
    case serviceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .connectionUnavailable:
            "Git operation helper is unavailable."
        case let .serviceFailed(message):
            message
        }
    }
}

public final class GitOperationHelperClient: @unchecked Sendable {
    public static let shared = GitOperationHelperClient()

    private let serviceName = "com.yueyi.GitOK.GitOperationService"

    public init() {}

    public func mergeBranches(
        repositoryURL: URL,
        sourceBranch: String,
        targetBranch: String
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let connection = NSXPCConnection(serviceName: serviceName)
            connection.remoteObjectInterface = NSXPCInterface(with: GitOperationXPCProtocol.self)

            var didResume = false
            let resume: (Result<Void, Error>) -> Void = { result in
                guard didResume == false else { return }
                didResume = true
                connection.invalidate()

                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            connection.invalidationHandler = {
                resume(.failure(GitOperationHelperError.connectionUnavailable))
            }
            connection.interruptionHandler = {
                resume(.failure(GitOperationHelperError.connectionUnavailable))
            }

            connection.resume()

            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                resume(.failure(error))
            } as? GitOperationXPCProtocol

            guard let proxy else {
                resume(.failure(GitOperationHelperError.connectionUnavailable))
                return
            }

            proxy.mergeBranches(
                repositoryPath: repositoryURL.path,
                sourceBranch: sourceBranch,
                targetBranch: targetBranch
            ) { response in
                if response["success"] as? Bool == true {
                    resume(.success(()))
                    return
                }

                let message = response["message"] as? String ?? GitOperationHelperError.connectionUnavailable.localizedDescription
                resume(.failure(GitOperationHelperError.serviceFailed(message)))
            }
        }
    }
}
