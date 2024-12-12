import Foundation

struct APIResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: String
    let duration: TimeInterval
} 