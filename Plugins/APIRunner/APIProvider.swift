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
        if !Thread.isMainThread {
            assert(false, "selectRequest must be called on the main thread")
        } 
        
        selectedRequestId = request?.id
        isEditing = false
        editingRequest = nil
    }

    func selectRequestById(_ id: UUID?) {
        if let id = id {
            selectRequest(requests.first { $0.id == id })
        } else {
            selectRequest(nil)
        }
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
            let urlRequest = try request.buildURLRequest()
            var currentRetry = 0
            
            while true {
                do {
                    let startTime = Date()
                    let (data, response) = try await URLSession.shared.data(for: urlRequest)
                    let httpResponse = response as! HTTPURLResponse
                    
                    // 如果需要重试
                    if (400...599).contains(httpResponse.statusCode) && currentRetry < request.maxRetries {
                        currentRetry += 1
                        // 指数退避重试
                        try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
                        continue
                    }
                    
                    let responseBody = String(data: data, encoding: .utf8) ?? ""
                    let duration = Date().timeIntervalSince(startTime)
                    let headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
                    
                    let apiResponse = APIResponse(
                        statusCode: httpResponse.statusCode,
                        headers: headers,
                        body: responseBody,
                        duration: duration,
                        requestURL: urlRequest.url!,
                        requestMethod: request.method.rawValue,
                        requestHeaders: urlRequest.allHTTPHeaderFields ?? [:],
                        requestBody: request.body,
                        requestTimestamp: startTime,
                        responseSize: data.count,
                        mimeType: httpResponse.mimeType,
                        textEncoding: httpResponse.textEncodingName,
                        suggestedFilename: httpResponse.suggestedFilename,
                        cookies: HTTPCookie.cookies(withResponseHeaderFields: headers, for: urlRequest.url!),
                        timeToFirstByte: duration, // 这里应该使用真实的 TTFB
                        dnsLookupTime: nil, // 需要使用 URLSessionTaskMetrics 来获取
                        tcpConnectionTime: nil,
                        tlsHandshakeTime: nil,
                        error: nil,
                        logs: [],
                        redirectChain: [],
                        tlsInfo: nil,
                        connectionInfo: nil
                    )
                    
                    await MainActor.run {
                        lastResponse = apiResponse
                    }
                    
                    return apiResponse
                } catch {
                    if currentRetry < request.maxRetries {
                        currentRetry += 1
                        // 指数退避重试
                        try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
                        continue
                    }
                    throw error
                }
            }
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
