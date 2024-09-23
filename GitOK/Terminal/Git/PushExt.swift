import Foundation
import OSLog
import SwiftUI

extension Git {
    func push(_ path: String, verbose: Bool = false) throws -> String {
        if verbose {
            os_log("\(self.label)Push")
        }
        
        return try Git.run("push --porcelain", path: path, verbose: verbose)
    }
}

#Preview {
    AppPreview()
}
