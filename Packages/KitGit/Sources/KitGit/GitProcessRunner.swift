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
            let message = String(data: errorData, encoding: .utf8) ?? "unknown error"
            throw Error.gitFailed(message)
        }
        return String(data: outputData, encoding: .utf8) ?? ""
    }
}
