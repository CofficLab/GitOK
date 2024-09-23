import Foundation
import OSLog
import SwiftUI

extension Git {
    func push(_ path: String) throws {
        let shell = Shell()
        do {
            try shell.run("git push", at: path)
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    AppPreview()
}
