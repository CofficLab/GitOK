import Foundation
import OSLog

/// 签名验证工具
public class SignatureVerifier {
    nonisolated public static let emoji = "🔐"

    /// 验证应用 bundle 签名（DMG 本身无签名，需验证其中的 .app）
    public static func verify(_ appBundleURL: URL) async throws {
        os_log(.info, "[SignatureVerifier] Verifying signature for %{public}s", appBundleURL.path)

        // 使用 codesign 命令验证签名
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = [
            "--verify",
            "--deep",
            "--strict",
            "--verbose",
            appBundleURL.path
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

        try await verifyDeveloperCertificate(appBundleURL)
    }

    /// 验证开发者证书与 Bundle ID
    private static func verifyDeveloperCertificate(_ appBundleURL: URL) async throws {
        // 获取签名证书信息
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-dvv", appBundleURL.path]

        let pipe = Pipe()
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 验证证书与 Bundle ID 是否匹配当前应用
        guard output.contains("Authority=") else {
            os_log(.error, "[SignatureVerifier] ✗ Invalid developer certificate")
            throw UpdateError.invalidDeveloperCertificate
        }

        if let bundleID = Bundle.main.bundleIdentifier,
           !output.contains("Identifier=\(bundleID)") {
            os_log(.error, "[SignatureVerifier] ✗ Bundle ID mismatch, expected %{public}s", bundleID)
            throw UpdateError.invalidDeveloperCertificate
        }

        os_log(.info, "[SignatureVerifier] ✓ Developer certificate valid")
    }
}