import Foundation
import OSLog
import SwiftUI

extension Git {
    static func revList(_ path: String) throws -> String {
        let currentBranch = try Git.getCurrentBranch(path)
        return try Git.run("rev-list HEAD ^origin/\(currentBranch.name)", path: path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
