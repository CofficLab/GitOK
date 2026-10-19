import Foundation

/// 诊断信息的文本生成与支持目录解析。
///
/// 原先这些逻辑内嵌在 `DiagnosticsSettingView` 中，只能靠真实 `Bundle.main`
/// 与文件系统间接观察；抽为纯类型后，版本号缺失、目录缺失等分支都能直接断言。
enum DiagnosticReport {
    /// 报告首行标题。
    static let title = "GitOK Diagnostics"

    /// 信息缺失时使用的占位符。
    static let placeholder = "-"

    /// 应用支持目录下的应用子目录名。
    static let applicationDirectoryName = "GitOK"

    /// Info.plist 中表示版本号的键。
    static let versionKey = "CFBundleShortVersionString"

    /// Info.plist 中表示构建号的键。
    static let buildKey = "CFBundleVersion"

    /// 生成诊断报告文本。
    ///
    /// - Parameters:
    ///   - bundle: 读取版本信息的 bundle；测试可传入自定义 bundle 字典。
    ///   - operatingSystemVersion: 系统版本描述字符串。
    /// - Returns: 三行报告；任一信息缺失时该行以 `-` 占位。
    static func text(
        bundle: Bundle = .main,
        operatingSystemVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    ) -> String {
        let version = bundle.object(forInfoDictionaryKey: versionKey) as? String ?? placeholder
        let build = bundle.object(forInfoDictionaryKey: buildKey) as? String ?? placeholder
        return """
        \(title)
        App Version: \(version)
        Build: \(build)
        macOS: \(operatingSystemVersion)
        """
    }

    /// 解析应用的 Application Support 目录（不存在支持目录时返回 `nil`）。
    ///
    /// - Parameter base: Application Support 根目录；`nil` 表示系统未提供。
    /// - Returns: 应用数据目录；`base` 为 `nil` 时同样返回 `nil`。
    static func applicationSupportURL(base: URL?) -> URL? {
        base?.appendingPathComponent(applicationDirectoryName, isDirectory: true)
    }
}
