import Foundation

/// Git 网络配置（代理 / SSL 证书），读写全局 git config。
public enum GitNetworkConfig {
    public struct Configuration: Equatable, Sendable {
        public var httpProxy: String
        public var httpsProxy: String
        public var sslVerify: Bool
        public var sslCAInfo: String

        public init(httpProxy: String = "", httpsProxy: String = "", sslVerify: Bool = true, sslCAInfo: String = "") {
            self.httpProxy = httpProxy
            self.httpsProxy = httpsProxy
            self.sslVerify = sslVerify
            self.sslCAInfo = sslCAInfo
        }
    }

    private static let home = FileManager.default.homeDirectoryForCurrentUser

    /// 读取全局网络配置。
    public static func loadGlobal() -> Configuration {
        Configuration(
            httpProxy: GitConfigReader.globalValue("http.proxy") ?? "",
            httpsProxy: GitConfigReader.globalValue("https.proxy") ?? "",
            sslVerify: (GitConfigReader.globalValue("http.sslVerify") ?? "true") != "false",
            sslCAInfo: GitConfigReader.globalValue("http.sslCAInfo") ?? ""
        )
    }

    /// 保存全局网络配置。
    public static func saveGlobal(_ configuration: Configuration) throws {
        try GitConfigReader.setGlobalValue("http.proxy", configuration.httpProxy)
        try GitConfigReader.setGlobalValue("https.proxy", configuration.httpsProxy)
        try GitConfigReader.setGlobalValue("http.sslVerify", configuration.sslVerify ? "true" : "false")
        try GitConfigReader.setGlobalValue("http.sslCAInfo", configuration.sslCAInfo)
    }
}
