import Foundation
import OSLog
import SwiftUI

extension Git {
    func revList(_ path: String) throws -> String {
        let verbose = true

        if verbose {
            os_log("RevList -> \(path)")
        }
        
        let currentBranch = try getCurrentBranch(path)

        if verbose {
            os_log("RevList -> \(currentBranch.name)")
        }

        return try self.run("rev-list HEAD ^origin/\(currentBranch.name)", path: path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
