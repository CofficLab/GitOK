import Foundation

/// 外部打开请求：`gitok://` URL 与目录路径之间的转换。
///
/// CLI 脚本 `gitok <path>` 把目标目录编码进 `gitok://open?path=<绝对路径>`，
/// 由 macOS Launch Services 路由到 GitOK。宿主（App 层）只负责接收 URL，
/// 解析交给本类型，便于单元测试覆盖编解码的一致性。
public enum ExternalOpenRequest {
    /// URL scheme 名。
    public static let urlScheme = "gitok"

    /// URL 的 host 段：表示「打开目录」。
    public static let openHost = "open"

    /// 构造指向指定目录的 URL。
    ///
    /// - Parameter path: 目录绝对路径。
    /// - Returns: `gitok://open?path=<百分号编码后的路径>`。
    public static func makeURL(forDirectory path: String) -> URL? {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = openHost
        components.path = "/" + openHost
        components.queryItems = [URLQueryItem(name: "path", value: path)]
        return components.url
    }

    /// 从 URL 中解析出要打开的目录绝对路径。
    ///
    /// 支持两种形态：
    /// - `gitok://open?path=<绝对路径>`：CLI 脚本使用的形式；
    /// - `file:///...`：用户把目录拖到 GitOK 图标上时的形式。
    ///
    /// - Returns: 规范化后的路径；URL 不受支持或缺少路径时返回 `nil`。
    public static func resolveDirectory(from url: URL) -> String? {
        if url.isFileURL {
            return url.standardizedFileURL.path
        }
        guard url.scheme?.lowercased() == urlScheme else { return nil }
        guard url.host?.lowercased() == openHost else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.queryItems?.first(where: { $0.name == "path" })?.value
        else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return (trimmed as NSString).expandingTildeInPath
    }
}
