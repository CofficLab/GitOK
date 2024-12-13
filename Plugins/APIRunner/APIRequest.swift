import Foundation

struct APIRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var url: String
    var method: HTTPMethod
    var headers: [String: String]
    var body: String?
    var contentType: ContentType
    
    var timeout: TimeInterval
    var maxRetries: Int
    var followRedirects: Bool
    var queryParameters: [String: String]
    var authentication: Authentication?
    
    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: String? = nil,
        contentType: ContentType = .json,
        timeout: TimeInterval = 30,
        maxRetries: Int = 0,
        followRedirects: Bool = true,
        queryParameters: [String: String] = [:],
        authentication: Authentication? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.contentType = contentType
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.followRedirects = followRedirects
        self.queryParameters = queryParameters
        self.authentication = authentication
    }
    
    enum HTTPMethod: String, Codable, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
        case head = "HEAD"
        case options = "OPTIONS"
    }
    
    enum ContentType: String, Codable, CaseIterable {
        case json = "application/json"
        case xml = "application/xml"
        case form = "application/x-www-form-urlencoded"
        case text = "text/plain"
        case multipart = "multipart/form-data"
    }
    
    enum Authentication: Codable, Hashable {
        case basic(username: String, password: String)
        case bearer(token: String)
        case apiKey(key: String, value: String, location: APIKeyLocation)
        
        enum APIKeyLocation: String, Codable {
            case header
            case query
        }
        
        func apply(to request: inout URLRequest) {
            switch self {
            case .basic(let username, let password):
                let credentials = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""
                request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
                
            case .bearer(let token):
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
            case .apiKey(let key, let value, let location):
                switch location {
                case .header:
                    request.setValue(value, forHTTPHeaderField: key)
                case .query:
                    if var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
                        var queryItems = components.queryItems ?? []
                        queryItems.append(URLQueryItem(name: key, value: value))
                        components.queryItems = queryItems
                        request.url = components.url
                    }
                }
            }
        }
    }
    
    func buildURL() -> URL? {
        guard var components = URLComponents(string: url) else {
            return nil
        }
        
        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { 
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        return components.url
    }
    
    func buildURLRequest() throws -> URLRequest {
        guard let url = buildURL() else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        authentication?.apply(to: &request)
        
        if let body = body {
            request.httpBody = body.data(using: .utf8)
        }
        
        return request
    }
} 