import Foundation
import Testing
@testable import GitOKAutomationKit

@Suite("GitOKAutomationServiceTests", .serialized)
struct GitOKAutomationServiceTests {
    @Test("Dispatch posts action notification")
    func dispatchPostsActionNotification() throws {
        let notificationCenter = NotificationCenter()
        let request = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockCommitSelected.rawValue,
            payload: ["hash": "abc123"]
        )
        let capture = RequestCapture()

        let token = notificationCenter.addObserver(
            forName: .gitOKAutomationActionReceived,
            object: nil,
            queue: nil
        ) { notification in
            let userInfo = notification.userInfo
            let action = userInfo?[GitOKAutomationUserInfoKey.action] as? String ?? ""
            let payload = userInfo?[GitOKAutomationUserInfoKey.payload] as? [String: String] ?? [:]
            capture.request = GitOKAutomationRequest(action: action, payload: payload)
        }
        defer { notificationCenter.removeObserver(token) }

        GitOKAutomationService.post(request, notificationCenter: notificationCenter, object: nil)

        let unwrappedRequest = try #require(capture.request)
        #expect(unwrappedRequest.action == GitOKAutomationAction.mockCommitSelected.rawValue)
        #expect(unwrappedRequest.payload["hash"] == "abc123")
    }

    @Test("Handle request returns ok for valid request")
    func handleRequestReturnsOK() {
        let body = #"{"action":"mock.working_tree.selected"}"#
        let data = Data("""
        POST /api/action HTTP/1.1\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        \r
        \(body)
        """.utf8)

        let response = GitOKAutomationService.shared.handleRequest(data)
        let text = String(decoding: response, as: UTF8.self)

        #expect(text.contains("HTTP/1.1 200 OK"))
        #expect(text.contains(#""status":"ok""#) || text.contains(#""status": "ok""#))
    }

    @Test("Handle request returns error response for invalid request")
    func handleRequestReturnsErrorResponseForInvalidRequest() {
        let response = GitOKAutomationService.shared.handleRequest(Data("""
        GET /api/action HTTP/1.1\r
        Content-Type: application/json\r
        \r
        {}
        """.utf8))
        let text = String(decoding: response, as: UTF8.self)

        #expect(text.contains("HTTP/1.1 404 Error"))
        #expect(text.contains(#""status":"error""#) || text.contains(#""status": "error""#))
    }

    @Test("Service start and stop are safe")
    func serviceStartAndStopAreSafe() async throws {
        let service = GitOKAutomationService.shared
        service.stop()

        service.start(port: 18767)
        try await Task.sleep(for: .milliseconds(150))

        #expect(service.port == 18767)

        service.start(port: 18768)
        #expect(service.port == 18767)

        service.stop()
        try await Task.sleep(for: .milliseconds(50))
        #expect(!service.isRunning)
    }

    @Test("Service respects disabled environment flag")
    func serviceRespectsDisabledEnvironmentFlag() async throws {
        let service = GitOKAutomationService.shared
        service.stop()

        let previousValue = ProcessInfo.processInfo.environment["GITOK_AUTOMATION_SERVER"]
        setenv("GITOK_AUTOMATION_SERVER", "false", 1)
        defer {
            if let previousValue {
                setenv("GITOK_AUTOMATION_SERVER", previousValue, 1)
            } else {
                unsetenv("GITOK_AUTOMATION_SERVER")
            }
            service.stop()
        }

        service.start(port: 18770)
        try await Task.sleep(for: .milliseconds(50))

        #expect(!service.isRunning)
    }

    @Test("HTTP completeness handles content length variants")
    func httpCompletenessHandlesContentLengthVariants() {
        let body = #"{"action":"mock.file.selected"}"#
        let complete = Data(
            "POST /api/action HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)".utf8
        )
        let incomplete = Data(
            "POST /api/action HTTP/1.1\r\nContent-Length: \(body.utf8.count + 4)\r\n\r\n\(body)".utf8
        )
        let noLength = Data(
            "POST /api/action HTTP/1.1\r\nContent-Type: application/json\r\n\r\n".utf8
        )

        #expect(GitOKAutomationService.isCompleteHTTPRequest(Data("POST /api/action HTTP/1.1".utf8)) == false)
        #expect(GitOKAutomationService.isCompleteHTTPRequest(Data([0xff, 0xfe, 13, 10, 13, 10])) == true)
        #expect(GitOKAutomationService.isCompleteHTTPRequest(complete) == true)
        #expect(GitOKAutomationService.isCompleteHTTPRequest(incomplete) == false)
        #expect(GitOKAutomationService.isCompleteHTTPRequest(noLength) == true)
        #expect(GitOKAutomationService.contentLength(from: "Content-Length: 12") == 12)
        #expect(GitOKAutomationService.contentLength(from: "content-length: invalid") == 0)
        #expect(GitOKAutomationService.contentLength(from: "Content-Type: application/json") == 0)
    }

    @Test("Service handles HTTP request over localhost")
    func serviceHandlesHTTPRequestOverLocalhost() async throws {
        let service = GitOKAutomationService.shared
        let port: UInt16 = 18769
        service.stop()
        service.start(port: port)
        defer { service.stop() }

        try await waitUntil(timeout: .seconds(2)) {
            service.isRunning
        }

        let capture = RequestCapture()
        let token = NotificationCenter.default.addObserver(
            forName: .gitOKAutomationActionReceived,
            object: nil,
            queue: nil
        ) { notification in
            let userInfo = notification.userInfo
            let action = userInfo?[GitOKAutomationUserInfoKey.action] as? String ?? ""
            let payload = userInfo?[GitOKAutomationUserInfoKey.payload] as? [String: String] ?? [:]
            capture.request = GitOKAutomationRequest(action: action, payload: payload)
        }
        defer { NotificationCenter.default.removeObserver(token) }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/api/action")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(#"{"action":"mock.project.selected","payload":{"path":"/tmp/repo"}}"#.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try #require(response as? HTTPURLResponse)
        let body = String(decoding: data, as: UTF8.self)

        #expect(httpResponse.statusCode == 200)
        #expect(body.contains(#""status":"ok""#) || body.contains(#""status": "ok""#))

        try await waitUntil(timeout: .seconds(2)) {
            capture.request != nil
        }
        let postedRequest = try #require(capture.request)
        #expect(postedRequest.action == GitOKAutomationAction.mockProjectSelected.rawValue)
        #expect(postedRequest.payload["path"] == "/tmp/repo")
    }

    private func waitUntil(
        timeout: Duration,
        condition: @escaping @Sendable () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if condition() {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("Timed out waiting for condition")
    }
}

private final class RequestCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var storedRequest: GitOKAutomationRequest?

    var request: GitOKAutomationRequest? {
        get {
            lock.withLock { storedRequest }
        }
        set {
            lock.withLock { storedRequest = newValue }
        }
    }
}
