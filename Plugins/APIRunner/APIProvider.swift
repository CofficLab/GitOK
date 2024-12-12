import Foundation
import SwiftUI
import MagicKit

class APIProvider: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var lastResponse: APIResponse?
    @Published private(set) var lastError: Error?
    @Published var selectedRequestId: UUID?
    @Published var isEditing = false
    @Published var editingRequest: APIRequest?
    
    func startEditing(_ request: APIRequest) {
        editingRequest = request
        isEditing = true
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