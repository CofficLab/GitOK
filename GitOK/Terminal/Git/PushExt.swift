import Foundation
import OSLog
import SwiftUI

extension Git {
    func push(_ path: String) throws -> String {
        let verbose = true
        if verbose {
            os_log("\(self.label)Push")
        }
        
        do {
            return try run("push --porcelain", path: path, verbose: verbose)
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    AppPreview()
}
