import Foundation

struct APIResponse {
    // 基本信息
    let statusCode: Int
    let headers: [String: String]
    let body: String
    let duration: TimeInterval
    
    // 请求信息
    let requestURL: URL
    let requestMethod: String
    let requestHeaders: [String: String]
    let requestBody: String?
    let requestTimestamp: Date
    
    // 响应详情
    let responseSize: Int
    let mimeType: String?
    let textEncoding: String?
    let suggestedFilename: String?
    let cookies: [HTTPCookie]
    
    // 性能指标
    let timeToFirstByte: TimeInterval
    let dnsLookupTime: TimeInterval?
    let tcpConnectionTime: TimeInterval?
    let tlsHandshakeTime: TimeInterval?
    
    // 错误信息
    let error: Error?
    
    // 控制台日志
    struct LogEntry {
        let timestamp: Date
        let level: LogLevel
        let message: String
        
        enum LogLevel {
            case info
            case warning
            case error
            case debug
        }
    }
    let logs: [LogEntry]
    
    // 重定向信息
    struct RedirectInfo {
        let sourceURL: URL
        let destinationURL: URL
        let statusCode: Int
        let timestamp: Date
    }
    let redirectChain: [RedirectInfo]
    
    // SSL/TLS 信息
    struct TLSInfo {
        let tlsProtocol: String
        let cipherSuite: String
        let certificateChain: [String]
        let certificateExpirationDate: Date
    }
    let tlsInfo: TLSInfo?
    
    // IP 信息
    struct ConnectionInfo {
        let localIP: String
        let remoteIP: String
        let remotePort: Int
    }
    let connectionInfo: ConnectionInfo?
} 