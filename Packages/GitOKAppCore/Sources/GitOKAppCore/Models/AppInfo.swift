import Foundation

/// 应用信息模型
public struct AppInfo: Sendable {
    public let name: String
    public let version: String
    public let build: String
    public let bundleIdentifier: String
    public let description: String
    public let website: String
    public let repository: String

    public init() {
        let bundle = Bundle.main

        self.name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "GitOK"
        self.version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        self.build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        self.bundleIdentifier = bundle.bundleIdentifier ?? "com.cofficlab.GitOK"
        self.description = bundle.object(forInfoDictionaryKey: "CFBundleGetInfoString") as? String
            ?? "一个现代化的 Git 客户端，让 Git 操作更加简单高效。"
        self.website = bundle.object(forInfoDictionaryKey: "Website") as? String
            ?? "https://github.com/CofficLab/GitOK"
        self.repository = bundle.object(forInfoDictionaryKey: "Repository") as? String
            ?? "https://github.com/CofficLab/GitOK"
    }
}
