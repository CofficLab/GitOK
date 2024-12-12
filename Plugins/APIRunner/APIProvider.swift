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
    @Published private(set) var editingRequest: APIRequest?
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
    
    func saveRequest(_ request: APIRequest, to project: Project) throws {
        os_log("saveRequest: starting save for request %@ to project %@", log: .default, type: .info, request.id.uuidString, project.title)
        
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
        
        // 如果正在编辑这个请求，更新编辑中的请求
        if editingRequest?.id == request.id {
            editingRequest = request
        }
        
        // 如果这个请求被选中，更新选中状态
        if selectedRequestId == request.id {
            selectRequest(request)
        }
        
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
    
    func updateRequest(_ request: APIRequest) throws {
        guard let project = currentProject else {
            throw APIError.noProjectSelected
        }
        
        try saveRequest(request, to: project)
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
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.rawValue
            urlRequest.allHTTPHeaderFields = request.headers
            
            if let body = request.body {
                urlRequest.httpBody = body.data(using: .utf8)
            }
            
            urlRequest.setValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
            
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            let httpResponse = response as! HTTPURLResponse
            
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            let duration = Date().timeIntervalSince(startTime)
            let headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            
            let apiResponse = APIResponse(
                statusCode: httpResponse.statusCode,
                headers: headers,
                body: responseBody,
                duration: duration
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
