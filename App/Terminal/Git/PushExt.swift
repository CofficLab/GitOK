import Foundation
import OSLog
import SwiftUI

extension Git {
    func push(_ path: String) throws {
        let shell = Shell()
        do {
            self.emitGitPushStart()
            _ = try shell.run("git push", at: path)
            self.emitGitPushSuccess()
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            self.emitGitPushFailed()
            throw error
        }
    }

    func push(_ path: String, username: String, token: String) throws {
        self.emitGitPushStart()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "push"]
        process.environment = ["GIT_ASKPASS": "echo", "GIT_USERNAME": username, "GIT_PASSWORD": token]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            self.emitGitPushFailed()
            throw NSError(domain: "GitError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }

        self.emitGitPushSuccess()
    }
}

#Preview {
    AppPreview()
}
