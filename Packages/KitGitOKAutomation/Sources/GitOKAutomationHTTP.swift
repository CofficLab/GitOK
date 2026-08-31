import Foundation

/// 自动化 HTTP 协议的解析与编码工具。
///
/// 这里实现的是一个面向本地调试的最小 HTTP 子集：只处理
/// `POST /api/action`，请求体必须是 JSON object。它不负责监听端口，
/// 也不负责分发事件，这些职责由 `GitOKAutomationService` 承担。
public enum GitOKAutomationHTTP {
    /// 自动化动作入口路径。
    public static let actionPath = "/api/action"

    /// 解析一段 HTTP request bytes。
    ///
    /// - Parameter data: 从本地 TCP 连接读取到的原始请求数据。
    /// - Returns: 成功时返回自动化请求；失败时返回可直接写回客户端的响应描述。
    public static func parseRequest(_ data: Data) -> GitOKAutomationParseResult {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return .failure(.error("Invalid request encoding"))
        }

        let components = requestString.components(separatedBy: "\r\n\r\n")
        guard let headPart = components.first, !headPart.isEmpty else {
            return .failure(.error("Malformed request"))
        }

        let bodyPart = components.dropFirst().joined(separator: "\r\n\r\n")
        let lines = headPart.components(separatedBy: "\r\n")
        let requestLine = lines[0]

        let requestLineParts = requestLine.components(separatedBy: " ")
        guard requestLineParts.count >= 2 else {
            return .failure(.error("Invalid request line"))
        }

        let method = requestLineParts[0]
        let path = requestLineParts[1]
        guard method == "POST", path == actionPath || path == "\(actionPath)/" else {
            return .failure(.error(statusCode: 404, "Not found. Use POST \(actionPath)"))
        }

        guard let bodyData = bodyPart.data(using: .utf8), !bodyData.isEmpty else {
            return .failure(.error("Missing JSON body"))
        }

        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
                return .failure(.error("Invalid JSON: expected object"))
            }

            guard let action = jsonObject["action"] as? String, !action.isEmpty else {
                return .failure(.error("Missing required field: action"))
            }

            let payload = parsePayload(jsonObject["payload"])
            return .success(GitOKAutomationRequest(action: action, payload: payload))
        } catch {
            return .failure(.error("JSON parse error: \(error.localizedDescription)"))
        }
    }

    /// 将自动化响应描述编码成完整 HTTP response bytes。
    ///
    /// - Parameter response: 业务响应描述。
    /// - Returns: 包含 status line、headers 和 JSON body 的 HTTP response 数据。
    public static func makeResponse(_ response: GitOKAutomationResponse) -> Data {
        let bodyDict: [String: String] = [
            "status": response.status,
            "message": response.message,
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: bodyDict)
        let statusText = response.statusCode == 200 ? "OK" : "Error"
        let header = "HTTP/1.1 \(response.statusCode) \(statusText)\r\n"
            + "Content-Type: application/json\r\n"
            + "Content-Length: \(bodyData.count)\r\n"
            + "Connection: close\r\n"
            + "\r\n"

        var data = Data(header.utf8)
        data.append(bodyData)
        return data
    }

    /// 将 JSON payload 转成 `[String: String]`。
    ///
    /// 只保留字符串、数字和布尔值，复杂对象会被忽略。这样能让 package 保持简单，
    /// 并避免把 App 业务结构塞进自动化基础设施。
    private static func parsePayload(_ rawPayload: Any?) -> [String: String] {
        guard let payload = rawPayload as? [String: Any] else {
            return [:]
        }

        var result: [String: String] = [:]
        for (key, value) in payload {
            switch value {
            case let string as String:
                result[key] = string
            case let bool as Bool:
                result[key] = bool ? "true" : "false"
            case let number as NSNumber:
                result[key] = number.stringValue
            default:
                continue
            }
        }
        return result
    }
}
