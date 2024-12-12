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
    
    func selectRequest(_ request: APIRequest?) {
        selectedRequestId = request?.id
        isEditing = false
        editingRequest = nil
    }
    
    func startEditing(_ request: APIRequest) {
        editingRequest = request
        isEditing = true
        
        if request.name == "New Request" {
            var baseName = "New Request"
            var counter = 1
            while requests.contains(where: { $0.name == baseName }) {
                counter += 1
                baseName = "New Request \(counter)"
            }
            editingRequest?.name = baseName
        }
    }
    
    func saveRequest(_ request: APIRequest, to project: Project) {
        var config = APIConfig.load(from: project)
        if let index = config.requests.firstIndex(where: { $0.id == request.id }) {
            config.requests[index] = request
        } else {
            config.requests.append(request)
        }
        try? config.save(to: project)
        
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index] = request
        } else {
            requests.append(request)
        }
        
        selectRequest(request)
    }
    
    func loadRequests(from project: Project) {
        let config = APIConfig.load(from: project)
        requests = config.requests
    }
    
    func stopEditing() {
        editingRequest = nil
        isEditing = false
    }
    
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

    func setSelectedRequestId(_ id: UUID?) {
        os_log("setSelectedRequestId: %@", log: .default, type: .info, id?.uuidString ?? "nil")
        selectedRequestId = id
    }

    func setRequests(_ requests: [APIRequest]) {
        os_log("setRequests: %@", log: .default, type: .info, requests.map { $0.id.uuidString }.joined(separator: ", "))
        self.requests = requests
    }
}

enum APIError: LocalizedError {
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        }
    }
} 
