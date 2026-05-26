import Foundation
import Network
import os

/// GitOK 本地自动化 HTTP 服务。
///
/// 该服务负责在本机回环地址上监听 HTTP 请求，将请求解析成
/// `GitOKAutomationRequest`，再通过 NotificationCenter 分发给 App 侧视图或控制器。
///
/// 设计边界：
/// - 只提供自动化基础设施，不依赖 GitOK App 的业务模型。
/// - 只监听 `127.0.0.1`，用于 Debug/开发环境。
/// - 不提供任意命令执行能力，动作必须由 App 侧白名单响应。
public final class GitOKAutomationService: @unchecked Sendable {
    /// 全局共享服务实例。
    public static let shared = GitOKAutomationService()

    /// 默认监听端口。
    public static let defaultPort: UInt16 = 18766

    /// 当前进程是否允许启用自动化服务。
    ///
    /// 设置环境变量 `GITOK_AUTOMATION_SERVER=false` 时会禁用服务。
    public static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["GITOK_AUTOMATION_SERVER"] != "false"
    }

    private let logger = Logger(subsystem: "com.coffic.gitok", category: "automation")
    private let queue = DispatchQueue(label: "com.coffic.gitok.automation.server", qos: .userInitiated)
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]

    /// 当前配置的监听端口。
    public private(set) var port: UInt16 = defaultPort

    /// 服务是否处于 ready 状态。
    public var isRunning: Bool {
        listener?.state == .ready
    }

    private init() {}

    /// 启动本地自动化 HTTP 服务。
    ///
    /// - Parameter port: 监听端口，默认使用 `defaultPort`。
    ///
    /// 如果环境变量禁用了服务，或服务已经启动，本方法会直接返回。
    public func start(port: UInt16 = defaultPort) {
        guard Self.isEnabled else {
            logger.info("🤖[automation] 自动化服务已被 GITOK_AUTOMATION_SERVER=false 禁用")
            return
        }

        guard listener == nil else {
            logger.warning("🤖[automation] 自动化服务已启动，忽略重复启动")
            return
        }

        self.port = port

        do {
            let parameters = NWParameters.tcp
            if let loopback = IPv4Address("127.0.0.1"),
               let endpointPort = NWEndpoint.Port(rawValue: port) {
                parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(loopback), port: endpointPort)
            }
            listener = try NWListener(using: parameters)
        } catch {
            logger.error("🤖[automation] 创建监听器失败：\(error.localizedDescription)")
            listener = nil
            return
        }

        listener?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.logger.info("🤖[automation] 自动化服务已启动：127.0.0.1:\(self.port)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .gitOKAutomationServerDidStart,
                        object: self,
                        userInfo: [GitOKAutomationUserInfoKey.port: Int(self.port)]
                    )
                }
            case .failed(let error):
                self.logger.error("🤖[automation] 自动化服务失败：\(error.localizedDescription)")
                self.stop()
            case .cancelled:
                self.logger.info("🤖[automation] 自动化服务已停止")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .gitOKAutomationServerDidStop, object: self)
                }
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener?.start(queue: queue)
    }

    /// 停止自动化服务并关闭所有活动连接。
    public func stop() {
        listener?.cancel()
        listener = nil
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
    }

    /// 接收并管理新的 TCP 连接。
    ///
    /// 连接建立后会进入 `receive(on:)` 读取 HTTP request。
    private func handleConnection(_ connection: NWConnection) {
        let connectionID = ObjectIdentifier(connection)
        connections[connectionID] = connection

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receive(on: connection)
            case .failed, .cancelled:
                self?.connections.removeValue(forKey: connectionID)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    /// 从连接读取请求、执行请求处理并写回响应。
    ///
    /// 请求可能被 TCP 分包，因此这里会持续累积数据，直到 header 和
    /// `Content-Length` 指定的 body 都读取完毕，再交给 HTTP 解析器处理。
    /// 响应发送完成后会主动关闭连接。
    private func receive(on connection: NWConnection, accumulatedData: Data = Data()) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] content, _, _, error in
            guard let self else { return }

            if let error {
                self.logger.warning("🤖[automation] 接收请求失败：\(error.localizedDescription)")
                connection.cancel()
                return
            }

            guard let content, !content.isEmpty else {
                connection.cancel()
                return
            }

            var requestData = accumulatedData
            requestData.append(content)

            guard Self.isCompleteHTTPRequest(requestData) else {
                self.receive(on: connection, accumulatedData: requestData)
                return
            }

            let response = self.handleRequest(requestData)
            connection.send(content: response, completion: .contentProcessed { [weak self] error in
                if let error {
                    self?.logger.warning("🤖[automation] 发送响应失败：\(error.localizedDescription)")
                }
                connection.cancel()
            })
        }
    }

    /// 判断当前累积的数据是否已经包含完整 HTTP 请求。
    ///
    /// 仅支持本 package 需要的简单 HTTP 场景：根据 `\r\n\r\n` 找 header/body
    /// 分隔点，并读取 `Content-Length` 判断 body 是否完整。没有声明
    /// `Content-Length` 时，只要 header 完整就认为请求完整。
    static func isCompleteHTTPRequest(_ data: Data) -> Bool {
        let separator = Data("\r\n\r\n".utf8)
        guard let separatorRange = data.range(of: separator) else {
            return false
        }

        let headerData = data[..<separatorRange.lowerBound]
        guard let header = String(data: headerData, encoding: .utf8) else {
            return true
        }

        let contentLength = contentLength(from: header)
        guard contentLength > 0 else {
            return true
        }

        let bodyStart = separatorRange.upperBound
        let bodyLength = data.distance(from: bodyStart, to: data.endIndex)
        return bodyLength >= contentLength
    }

    /// 从 HTTP header 中提取 `Content-Length`。
    static func contentLength(from header: String) -> Int {
        for line in header.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2,
                  parts[0].lowercased() == "content-length" else {
                continue
            }
            return Int(parts[1]) ?? 0
        }
        return 0
    }

    /// 分发已经解析出的自动化请求。
    ///
    /// 该方法会记录稳定日志，并在主队列上发出 `.gitOKAutomationActionReceived` 通知。
    /// - Parameter request: 已解析的自动化请求。
    /// - Returns: 可返回给 HTTP 客户端的成功响应。
    @discardableResult
    public func dispatch(_ request: GitOKAutomationRequest) -> GitOKAutomationResponse {
        logger.info("🤖[automation] 分发动作：\(request.action, privacy: .public)")

        DispatchQueue.main.async {
            Self.post(request, notificationCenter: .default, object: self)
        }

        return .ok()
    }

    /// 向指定 NotificationCenter 发送自动化动作通知。
    ///
    /// 该方法主要用于隔离可测试的通知分发逻辑；运行时通常由 `dispatch(_:)` 调用。
    static func post(
        _ request: GitOKAutomationRequest,
        notificationCenter: NotificationCenter,
        object: Any?
    ) {
        notificationCenter.post(
            name: .gitOKAutomationActionReceived,
            object: object,
            userInfo: [
                GitOKAutomationUserInfoKey.action: request.action,
                GitOKAutomationUserInfoKey.payload: request.payload,
            ]
        )
    }

    /// 处理原始 HTTP request bytes。
    ///
    /// - Parameter data: 原始 HTTP 请求数据。
    /// - Returns: 完整 HTTP response bytes。
    public func handleRequest(_ data: Data) -> Data {
        switch GitOKAutomationHTTP.parseRequest(data) {
        case .success(let request):
            return GitOKAutomationHTTP.makeResponse(dispatch(request))
        case .failure(let response):
            return GitOKAutomationHTTP.makeResponse(response)
        }
    }
}
