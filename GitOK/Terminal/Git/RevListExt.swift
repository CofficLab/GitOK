import Foundation
import OSLog
import SwiftUI

extension Git {
    func revList(_ path: String) throws -> String {
        let currentBranch = try getCurrentBranch(path)
        return try self.run("rev-list HEAD ^origin/\(currentBranch.name)", path: path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
