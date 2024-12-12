import Foundation

struct APIRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var url: String
    var method: HTTPMethod
    var headers: [String: String]
    var body: String?
    var contentType: ContentType
    
    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: String? = nil,
        contentType: ContentType = .json
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.contentType = contentType
    }
    
    enum HTTPMethod: String, Codable, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    enum ContentType: String, Codable, CaseIterable {
        case json = "application/json"
        case xml = "application/xml"
        case form = "application/x-www-form-urlencoded"
        case text = "text/plain"
    }
} 