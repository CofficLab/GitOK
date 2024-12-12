import Foundation
import SwiftUI
import MagicKit
import OSLog

class APIProvider: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var lastResponse: APIResponse?
    @Published private(set) var lastError: Error?
    @Published private(set) var selectedRequestId: UUID?
    @Published private(set) var isEditing = false
    @Published var editingRequest: APIRequest?
    @Published private(set) var requests: [APIRequest] = []
    
    private var currentProject: Project?
    
    // MARK: - Project Management
    
    func setCurrentProject(_ project: Project?) {
        currentProject = project
        if let project = project {
            loadRequests(from: project)
        }
    }
    
    // MARK: - Request Management
    
    func loadRequests(from project: Project) {
        let config = APIConfig.load(from: project)
        requests = config.requests
    }
    
    func saveRequest(_ request: APIRequest, to project: Project, reason: String) throws {
        os_log("saveRequest: starting save for request %@ to project %@", log: .default, type: .info, request.id.uuidString, project.title)
        os_log("  ➡️ Title: \(request.name)")
        os_log("  ➡️ Reason: \(reason)")
        
        // 更新内存中的请求列表
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            os_log("saveRequest: updating existing request at index %d", log: .default, type: .debug, index)
            requests[index] = request
        } else {
            os_log("saveRequest: adding new request", log: .default, type: .debug)
            requests.append(request)
        }
        
        // 保存到磁盘
        try saveRequests(to: project)
        
//        // 如果正在编辑这个请求，更新编辑中的请求
//        if editingRequest?.id == request.id {
//            editingRequest = request
//        }
//        
//        // 如果这个请求被选中，更新选中状态
//        if selectedRequestId == request.id {
//            selectRequest(request)
//        }
        
        os_log("saveRequest: completed successfully", log: .default, type: .info)
    }
    
    func createNewRequest() -> APIRequest {
        var newRequest = APIRequest(name: "New Request", url: "")
        
        // 生成唯一名称
        if newRequest.name == "New Request" {
            var baseName = "New Request"
            var counter = 1
            while requests.contains(where: { $0.name == baseName }) {
                counter += 1
                baseName = "New Request \(counter)"
            }
            newRequest.name = baseName
        }
        
        // 添加到内存中的列表
        requests.append(newRequest)
        
        // 保存到磁盘
        if let project = currentProject {
            try? saveRequests(to: project)
        }
        
        return newRequest
    }
    
    func updateRequest(_ request: APIRequest, reason: String) throws {
        guard let project = currentProject else {
            throw APIError.noProjectSelected
        }
        
        try saveRequest(request, to: project, reason: reason + " 🐛 UpdateRequest")
    }
    
    func deleteRequest(_ request: APIRequest) throws {
        guard let project = currentProject else {
            throw APIError.noProjectSelected
        }
        
        requests.removeAll { $0.id == request.id }
        try saveRequests(to: project)
        
        // 如果删除的是正在编辑的请求，清除编辑状态
        if editingRequest?.id == request.id {
            stopEditing()
        }
        
        // 如果删除的是选中的请求，清除选中状态
        if selectedRequestId == request.id {
            selectRequest(nil)
        }
    }
    
    private func saveRequests(to project: Project) throws {
        let config = APIConfig(requests: requests)
        try config.save(to: project)
    }
    
    // MARK: - Selection Management
    
    func selectRequest(_ request: APIRequest?) {
        selectedRequestId = request?.id
        isEditing = false
        editingRequest = nil
    }
    
    func startEditing(_ request: APIRequest) {
        editingRequest = request
        isEditing = true
    }
    
    func stopEditing() {
        editingRequest = nil
        isEditing = false
    }
    
    // MARK: - Request Execution
    
    func sendRequest(_ request: APIRequest) async throws -> APIResponse {
        await MainActor.run {
            lastError = nil
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            guard let url = URL(string: request.url) else {
                throw APIError.invalidURL
            }
            
            // 创建请求
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.rawValue
            urlRequest.allHTTPHeaderFields = request.headers
            
            if let body = request.body {
                urlRequest.httpBody = body.data(using: .utf8)
            }
            urlRequest.setValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
            
            // 记录请求开始时间和信息
            let requestTimestamp = Date()
            var logs: [APIResponse.LogEntry] = []
            logs.append(.init(
                timestamp: requestTimestamp,
                level: .info,
                message: "Starting request to \(url.absoluteString)"
            ))
            
            // 创建URLSession配置
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = HTTPCookieStorage.shared
            configuration.httpCookieAcceptPolicy = .always
            
            // 创建自定义URLSession以获取指标
            let session = URLSession(configuration: configuration)
            
            // 发送请求并收集指标
            var timeToFirstByte: TimeInterval?
            var dnsLookupTime: TimeInterval?
            var tcpConnectionTime: TimeInterval?
            var tlsHandshakeTime: TimeInterval?
            
            let taskMetrics = TaskMetrics()
            let (data, response) = try await session.data(for: urlRequest, delegate: taskMetrics)
            let httpResponse = response as! HTTPURLResponse
            
            // 处理响应
            let responseTimestamp = Date()
            let duration = responseTimestamp.timeIntervalSince(requestTimestamp)
            
            // 获取响应体
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            
            // 获取Cookies
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            
            // 获取TLS信息
            var tlsInfo: APIResponse.TLSInfo?
            if !taskMetrics.certificateChain.isEmpty {
                tlsInfo = APIResponse.TLSInfo(
                    tlsProtocol: taskMetrics.tlsProtocolVersion ?? "Unknown",
                    cipherSuite: taskMetrics.tlsCipherSuite ?? "Unknown",
                    certificateChain: taskMetrics.certificateChain.map { $0.base64EncodedString() },
                    certificateExpirationDate: Date()
                )
            }
            
            // 创建APIResponse
            let apiResponse = APIResponse(
                // 基本信息
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                body: responseBody,
                duration: duration,
                
                // 请求信息
                requestURL: url,
                requestMethod: request.method.rawValue,
                requestHeaders: request.headers,
                requestBody: request.body,
                requestTimestamp: requestTimestamp,
                
                // 响应详情
                responseSize: data.count,
                mimeType: httpResponse.mimeType,
                textEncoding: httpResponse.textEncodingName,
                suggestedFilename: httpResponse.suggestedFilename,
                cookies: cookies,
                
                // 性能指标
                timeToFirstByte: timeToFirstByte ?? 0,
                dnsLookupTime: dnsLookupTime,
                tcpConnectionTime: tcpConnectionTime,
                tlsHandshakeTime: tlsHandshakeTime,
                
                // 错误信息
                error: nil,
                
                // 日志
                logs: logs,
                
                // 重定向信息
                redirectChain: taskMetrics.redirects,
                
                // TLS信息
                tlsInfo: tlsInfo,
                
                // 连接信息
                connectionInfo: taskMetrics.connectionInfo
            )
            
            await MainActor.run {
                lastResponse = apiResponse
            }
            
            return apiResponse
        } catch {
            await MainActor.run {
                lastError = error
            }
            throw error
        }
    }
}

// URLSession指标收集器
private class TaskMetrics: NSObject, URLSessionTaskDelegate, URLSessionDelegate {
    var tlsProtocolVersion: String?
    var tlsCipherSuite: String?
    var redirects: [APIResponse.RedirectInfo] = []
    var connectionInfo: APIResponse.ConnectionInfo?
    var certificateChain: [Data] = []
    
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust,
           let certificate = SecTrustGetCertificateAtIndex(trust, 0) {
            let certificateData = SecCertificateCopyData(certificate) as Data
            certificateChain.append(certificateData)
        }
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let lastMetric = metrics.transactionMetrics.last {
            // 获取 TLS 协议版本
            if let negotiatedTLSProtocolVersion = lastMetric.negotiatedTLSProtocolVersion {
                tlsProtocolVersion = String(describing: negotiatedTLSProtocolVersion)
            }
            
            // 获取密码套件
            if let negotiatedCipherSuite = lastMetric.negotiatedTLSCipherSuite {
                tlsCipherSuite = String(describing: negotiatedCipherSuite)
            }
        }
        
        // 收集重定向信息
        for metric in metrics.transactionMetrics {
            if let source = metric.request.url,
               let destination = metric.response?.url,
               let response = metric.response as? HTTPURLResponse,
               let timestamp = metric.responseEndDate {
                redirects.append(APIResponse.RedirectInfo(
                    sourceURL: source,
                    destinationURL: destination,
                    statusCode: response.statusCode,
                    timestamp: timestamp
                ))
            }
        }
        
        // 收集连接信息
        if let connMetrics = metrics.transactionMetrics.last {
            if let remoteAddress = task.currentRequest?.url?.host {
                connectionInfo = APIResponse.ConnectionInfo(
                    localIP: "127.0.0.1", // 需要额外工作来获取实际本地IP
                    remoteIP: remoteAddress,
                    remotePort: task.currentRequest?.url?.port ?? 80
                )
            }
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case noProjectSelected
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noProjectSelected:
            return "No project selected"
        }
    }
} 
