import Foundation
import OSLog
import SwiftUI

extension Git {
    func push(_ path: String) throws {
        let shell = Shell()
        do {
            self.emitGitPushing()
            _ = try shell.run("git push", at: path)
            self.emitGitPushSuccess()
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            self.emitGitPushFailed()
            throw error
        }
    }
}

#Preview {
    AppPreview()
}
