import Foundation
import Testing
@testable import GitOKAutomationKit

@Suite("GitOKAutomationHTTPTests")
struct GitOKAutomationHTTPTests {
    @Test("Parses valid action request")
    func parsesValidActionRequest() throws {
        let data = httpRequest(body: #"{"action":"mock.commit.selected","payload":{"hash":"abc123"}}"#)
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .success(let request) = result else {
            Issue.record("Expected request to parse")
            return
        }

        #expect(request.action == GitOKAutomationAction.mockCommitSelected.rawValue)
        #expect(request.payload["hash"] == "abc123")
        #expect(request.knownAction == .mockCommitSelected)
    }

    @Test("Parses trailing slash action path")
    func parsesTrailingSlashActionPath() {
        let data = httpRequest(path: "/api/action/", body: #"{"action":"mock.working_tree.selected"}"#)
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .success(let request) = result else {
            Issue.record("Expected trailing slash path to parse")
            return
        }

        #expect(request.knownAction == .mockWorkingTreeSelected)
    }

    @Test("Payload converts primitive values to strings and ignores complex values")
    func payloadConvertsPrimitiveValuesToStrings() {
        let data = httpRequest(
            body: #"{"action":"mock.file.selected","payload":{"path":"APP/App.swift","line":42,"active":true,"nested":{"ignored":true}}}"#
        )
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .success(let request) = result else {
            Issue.record("Expected payload to parse")
            return
        }

        #expect(request.payload["path"] == "APP/App.swift")
        #expect(request.payload["line"] == "42")
        #expect(request.payload["active"] == "true")
        #expect(request.payload["nested"] == nil)
    }

    @Test("Rejects unsupported path")
    func rejectsUnsupportedPath() {
        let data = Data("""
        POST /wrong HTTP/1.1\r
        Content-Type: application/json\r
        \r
        {"action":"mock.commit.selected"}
        """.utf8)

        let result = GitOKAutomationHTTP.parseRequest(data)
        guard case .failure(let response) = result else {
            Issue.record("Expected unsupported path to fail")
            return
        }

        #expect(response.statusCode == 404)
        #expect(response.status == "error")
    }

    @Test("Rejects malformed request")
    func rejectsMalformedRequest() {
        let result = GitOKAutomationHTTP.parseRequest(Data("".utf8))

        guard case .failure(let response) = result else {
            Issue.record("Expected malformed request to fail")
            return
        }

        #expect(response.message == "Malformed request")
    }

    @Test("Rejects invalid request encoding")
    func rejectsInvalidRequestEncoding() {
        let result = GitOKAutomationHTTP.parseRequest(Data([0xff, 0xfe, 0xfd]))

        guard case .failure(let response) = result else {
            Issue.record("Expected invalid UTF-8 to fail")
            return
        }

        #expect(response.message == "Invalid request encoding")
    }

    @Test("Rejects invalid request line")
    func rejectsInvalidRequestLine() {
        let result = GitOKAutomationHTTP.parseRequest(Data("""
        POST\r
        Content-Type: application/json\r
        \r
        {}
        """.utf8))

        guard case .failure(let response) = result else {
            Issue.record("Expected invalid request line to fail")
            return
        }

        #expect(response.message == "Invalid request line")
    }

    @Test("Rejects missing JSON body")
    func rejectsMissingJSONBody() {
        let result = GitOKAutomationHTTP.parseRequest(Data("""
        POST /api/action HTTP/1.1\r
        Content-Type: application/json\r
        \r
        
        """.utf8))

        guard case .failure(let response) = result else {
            Issue.record("Expected missing body to fail")
            return
        }

        #expect(response.message == "Missing JSON body")
    }

    @Test("Rejects invalid JSON")
    func rejectsInvalidJSON() {
        let data = httpRequest(body: #"{"action":"mock.commit.selected""#)
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .failure(let response) = result else {
            Issue.record("Expected invalid JSON to fail")
            return
        }

        #expect(response.message.hasPrefix("JSON parse error:"))
    }

    @Test("Rejects non-object JSON")
    func rejectsNonObjectJSON() {
        let data = httpRequest(body: #"["mock.commit.selected"]"#)
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .failure(let response) = result else {
            Issue.record("Expected non-object JSON to fail")
            return
        }

        #expect(response.message == "Invalid JSON: expected object")
    }

    @Test("Rejects missing action")
    func rejectsMissingAction() {
        let data = httpRequest(body: #"{"payload":{"hash":"abc123"}}"#)
        let result = GitOKAutomationHTTP.parseRequest(data)

        guard case .failure(let response) = result else {
            Issue.record("Expected missing action to fail")
            return
        }

        #expect(response.statusCode == 400)
        #expect(response.message == "Missing required field: action")
    }

    @Test("Response contains JSON status")
    func responseContainsJSONStatus() throws {
        let data = GitOKAutomationHTTP.makeResponse(.ok())
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("HTTP/1.1 200 OK"))
        #expect(text.contains(#""status":"ok""#) || text.contains(#""status": "ok""#))
        #expect(text.contains(#""message":"动作已分发""#) || text.contains(#""message": "动作已分发""#))
    }

    @Test("Error response contains status code and message")
    func errorResponseContainsStatusCodeAndMessage() {
        let data = GitOKAutomationHTTP.makeResponse(.error(statusCode: 404, "No route"))
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("HTTP/1.1 404 Error"))
        #expect(text.contains(#""status":"error""#) || text.contains(#""status": "error""#))
        #expect(text.contains(#""message":"No route""#) || text.contains(#""message": "No route""#))
    }

    private func httpRequest(path: String = "/api/action", body: String) -> Data {
        Data("""
        POST \(path) HTTP/1.1\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        \r
        \(body)
        """.utf8)
    }
}
