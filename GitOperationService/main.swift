import Foundation
import GitCoreKit

final class GitOperationService: NSObject, NSXPCListenerDelegate, GitOperationXPCProtocol {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: GitOperationXPCProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func mergeBranches(
        repositoryPath: String,
        sourceBranch: String,
        targetBranch: String,
        withReply reply: @escaping (NSDictionary) -> Void
    ) {
        autoreleasepool {
            do {
                GitRuntime.initialize()
                let repository = GitRepositoryCLI(repositoryURL: URL(fileURLWithPath: repositoryPath))
                try repository.mergeBranches(fromBranch: sourceBranch, toBranch: targetBranch)
                reply(["success": true])
            } catch {
                reply([
                    "success": false,
                    "message": error.localizedDescription,
                ])
            }
        }
    }
}

let delegate = GitOperationService()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
