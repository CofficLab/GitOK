import Foundation
import Testing
@testable import GitOKAutomationKit

@Suite("GitOKAutomationViewActionHandlersTests")
struct GitOKAutomationViewActionHandlersTests {
    @Test("Notification is converted to request")
    func notificationIsConvertedToRequest() throws {
        let notification = Notification(
            name: .gitOKAutomationActionReceived,
            object: nil,
            userInfo: [
                GitOKAutomationUserInfoKey.action: GitOKAutomationAction.mockFileSelected.rawValue,
                GitOKAutomationUserInfoKey.payload: ["path": "APP/App.swift"],
            ]
        )

        let request = try #require(GitOKAutomationViewActionHandlers.request(from: notification))
        #expect(request.action == GitOKAutomationAction.mockFileSelected.rawValue)
        #expect(request.payload["path"] == "APP/App.swift")

        let requestWithoutPayload = try #require(GitOKAutomationViewActionHandlers.request(from: Notification(
            name: .gitOKAutomationActionReceived,
            object: nil,
            userInfo: [GitOKAutomationUserInfoKey.action: GitOKAutomationAction.mockWorkingTreeSelected.rawValue]
        )))
        #expect(requestWithoutPayload.payload.isEmpty)

        #expect(GitOKAutomationViewActionHandlers.request(from: Notification(name: .gitOKAutomationActionReceived)) == nil)
    }

    @Test("Commit handler only receives matching action")
    func commitHandlerOnlyReceivesMatchingAction() {
        var receivedHash: String?
        let handler = GitOKAutomationViewActionHandlers.commitSelected { hash in
            receivedHash = hash
        }

        handler(.init(action: GitOKAutomationAction.mockFileSelected.rawValue, payload: ["path": "APP/App.swift"]))
        #expect(receivedHash == nil)

        handler(.init(action: GitOKAutomationAction.mockCommitSelected.rawValue, payload: ["hash": "abc123"]))
        #expect(receivedHash == "abc123")
    }

    @Test("Working tree handler only receives matching action")
    func workingTreeHandlerOnlyReceivesMatchingAction() {
        var count = 0
        let handler = GitOKAutomationViewActionHandlers.workingTreeSelected {
            count += 1
        }

        handler(.init(action: GitOKAutomationAction.mockCommitSelected.rawValue, payload: ["hash": "abc123"]))
        #expect(count == 0)

        handler(.init(action: GitOKAutomationAction.mockWorkingTreeSelected.rawValue))
        #expect(count == 1)
    }

    @Test("File handler only receives matching action")
    func fileHandlerOnlyReceivesMatchingAction() {
        var receivedPath: String?
        let handler = GitOKAutomationViewActionHandlers.fileSelected { path in
            receivedPath = path
        }

        handler(.init(action: GitOKAutomationAction.mockProjectSelected.rawValue, payload: ["path": "/tmp/repo"]))
        #expect(receivedPath == nil)

        handler(.init(action: GitOKAutomationAction.mockFileSelected.rawValue, payload: ["path": "APP/App.swift"]))
        #expect(receivedPath == "APP/App.swift")
    }

    @Test("Project handler only receives matching action")
    func projectHandlerOnlyReceivesMatchingAction() {
        var receivedPath: String?
        let handler = GitOKAutomationViewActionHandlers.projectSelected { path in
            receivedPath = path
        }

        handler(.init(action: GitOKAutomationAction.mockFileSelected.rawValue, payload: ["path": "APP/App.swift"]))
        #expect(receivedPath == nil)

        handler(.init(action: GitOKAutomationAction.mockProjectSelected.rawValue, payload: ["path": "/tmp/repo"]))
        #expect(receivedPath == "/tmp/repo")
    }
}
