import Foundation

/// 更新错误定义
public enum UpdateError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError
    case downloadFailed
    case allDownloadURLsFailed
    case signatureVerificationFailed(String)
    case invalidDeveloperCertificate
    case installationFailed(String)
    case dmgMountFailed
    case appReplacementFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的下载链接"
        case .networkError:
            return "网络连接失败"
        case .downloadFailed:
            return "下载失败"
        case .allDownloadURLsFailed:
            return "所有下载源均失败"
        case .signatureVerificationFailed(let msg):
            return "签名验证失败: \(msg)"
        case .invalidDeveloperCertificate:
            return "开发者证书无效"
        case .installationFailed(let msg):
            return "安装失败: \(msg)"
        case .dmgMountFailed:
            return "DMG 挂载失败"
        case .appReplacementFailed:
            return "应用替换失败"
        }
    }
}