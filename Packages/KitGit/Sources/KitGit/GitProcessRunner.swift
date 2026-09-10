import Foundation

/// 统一 git CLI 执行入口（供 KitGit 内各加载器复用）。
///
/// 当前阶段使用系统自带 git（macOS 预装）以零第三方依赖读取 git 数据；
/// 后续若迁移到 LibGit2（旧版方案），只需替换本执行器。
public enum GitProcessRunner {
    private final class DataBox: @unchecked Sendable {
        var value = Data()
    }

    public enum Error: Swift.Error, LocalizedError {
        case gitUnavailable(String)
        case gitFailed(String)

        public var errorDescription: String? {
            switch self {
            case .gitUnavailable(let message):
                String(format: LumiPluginLocalization.string("Git unavailable: %@", bundle: .module), message)
            case .gitFailed(let message):
                message
            }
        }
    }

    /// 在指定仓库目录执行 git 命令并返回标准输出（UTF-8）。
    /// 非零退出码抛 `gitFailed`，输出与 stderr 一并带出。
    ///
    /// `successExitCodes` 用于容忍"有差异即返回非零"的命令（如
    /// `git diff --no-index` 有差异时退出码为 1，属正常结果）。
    public static func run(
        _ arguments: [String],
        in repository: URL,
        successExitCodes: Set<Int32> = [0]
    ) throws -> String {
        var outputData = Data()
        try stream(
            arguments,
            in: repository,
            successExitCodes: successExitCodes
        ) { data in
            outputData.append(data)
            return true
        }
        return Self.decode(outputData)
    }

    /// 流式读取标准输出。回调返回 `false` 时会尽早停止子进程，适合只需要
    /// 某一页结果的 Git 查询；整个过程中不会把标准输出拼成一个大字符串。
    public static func stream(
        _ arguments: [String],
        in repository: URL,
        successExitCodes: Set<Int32> = [0],
        chunkSize: Int = 64 * 1024,
        onOutput: (Data) -> Bool
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repository

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw Error.gitUnavailable(error.localizedDescription)
        }

        // stderr 必须与 stdout 并行消费，否则 git 在输出大量警告时可能因为
        // stderr 管道写满而无法继续，导致 stdout 读取永远等不到结束。
        let errorGroup = DispatchGroup()
        let errorData = DataBox()
        errorGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            errorData.value = errorPipe.fileHandleForReading.readDataToEndOfFile()
            errorGroup.leave()
        }

        var shouldStop = false
        while true {
            let data = outputPipe.fileHandleForReading.readData(ofLength: max(chunkSize, 1))
            if data.isEmpty { break }
            if !onOutput(data) {
                shouldStop = true
                process.terminate()
                break
            }
        }

        process.waitUntilExit()
        // 终止早停后仍然清空剩余管道，避免文件描述符和子进程资源泄漏。
        _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
        errorGroup.wait()

        guard shouldStop || successExitCodes.contains(process.terminationStatus) else {
            let message = Self.decode(errorData.value, fallback: "unknown error")
            throw Error.gitFailed(message)
        }
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
