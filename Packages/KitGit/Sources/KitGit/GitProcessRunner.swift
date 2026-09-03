import Foundation

/// 统一 git CLI 执行入口（供 KitGit 内各加载器复用）。
///
/// 当前阶段使用系统自带 git（macOS 预装）以零第三方依赖读取 git 数据；
/// 后续若迁移到 LibGit2（旧版方案），只需替换本执行器。
public enum GitProcessRunner {
    public enum Error: Swift.Error, LocalizedError {
        case gitUnavailable(String)
        case gitFailed(String)

        public var errorDescription: String? {
            switch self {
            case .gitUnavailable(let message):
                "Git 不可用：\(message)"
            case .gitFailed(let message):
                message
            }
        }
    }

    /// 在指定仓库目录执行 git 命令并返回标准输出（UTF-8）。
    /// 非零退出码抛 `gitFailed`，输出与 stderr 一并带出。
    public static func run(_ arguments: [String], in repository: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repository

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw Error.gitUnavailable(error.localizedDescription)
        }
        process.waitUntilExit()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let message = Self.decode(errorData, fallback: "unknown error")
            throw Error.gitFailed(message)
        }
        return Self.decode(outputData)
    }

    /// 容错解码 git 输出：优先 UTF-8（无损保留）；失败则回退 GB18030
    /// （覆盖 GBK/GB2312，国内仓库常见编码）；仍失败则 lossy 解码
    /// （非法字节替换为 U+FFFD，保证不吞掉整段 diff）。
    /// 修复：文件内容为非 UTF-8 时 `String(data:, encoding: .utf8)`
    /// 返回 nil，导致 diff 被判定为 "No Text Diff"。
    private static func decode(_ data: Data, fallback: String = "") -> String {
        if data.isEmpty { return fallback }
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        let gb18030 = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
        if let gb = String(data: data, encoding: gb18030) {
            return gb
        }
        let lossy = String(decoding: data, as: UTF8.self)
        return lossy.isEmpty ? fallback : lossy
    }
}
