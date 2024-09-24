import Foundation
import OSLog
import SwiftUI

extension Git {
    func pull(_ path: String) throws {
        let shell = Shell()
        do {
            self.emitGitPullStart()
            _ = try shell.run("git pull", at: path)
            self.emitGitPullSuccess()
        } catch let error {
            os_log(.error, "拉取失败: \(error.localizedDescription)")
            self.emitGitPullFailed()
            throw error
        }
    }
}

#Preview {
    AppPreview()
}
