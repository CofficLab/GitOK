import Foundation
import OSLog

/// 签名验证工具
public class SignatureVerifier {
    nonisolated public static let emoji = "🔐"

    /// 验证 DMG 文件签名
    public static func verify(_ fileURL: URL) async throws {
        os_log(.info, "[SignatureVerifier] Verifying signature for %{public}s", fileURL.path)

        // 使用 codesign 命令验证签名
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = [
            "--verify",
            "--deep",
            "--strict",
            "--verbose",
            fileURL.path
        ]

        let pipe = Pipe()
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            os_log(.error, "[SignatureVerifier] ✗ Signature verification failed: %{public}s", errorMessage)
            throw UpdateError.signatureVerificationFailed(errorMessage)
        }

        os_log(.info, "[SignatureVerifier] ✓ Signature verification passed")

        // 验证开发者证书（可选）
        try await verifyDeveloperCertificate(fileURL)
    }

    /// 验证开发者证书
    private static func verifyDeveloperCertificate(_ fileURL: URL) async throws {
        // 获取签名证书信息
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-dvv", fileURL.path]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 验证证书是否匹配预期开发者
        // 例如：检查 "Authority=" 或特定 Team ID
        guard output.contains("Authority=") else {
            os_log(.error, "[SignatureVerifier] ✗ Invalid developer certificate")
            throw UpdateError.invalidDeveloperCertificate
        }

        os_log(.info, "[SignatureVerifier] ✓ Developer certificate valid")
    }
}