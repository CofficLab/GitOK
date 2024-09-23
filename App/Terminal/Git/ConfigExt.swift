import Foundation
import OSLog
import SwiftUI

extension Git {
    func getCredentialHelper(_ path: String) throws -> String {
        do {
            return try self.run("config credential.helper", path: path)
        } catch let error {
            os_log(.error, "获取凭证失败: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    AppPreview()
}
