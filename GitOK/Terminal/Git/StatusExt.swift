import Foundation
import OSLog
import SwiftUI

extension Git {
    static func status(_ path: String) throws -> String {
        try Git.run("status", path: path)
    }

    func changedFile(_ path: String, verbose: Bool = false) -> [File] {
        os_log("\(self.label)GetChangedFile for->\(path)")
        if Git.isGitProject(path: path) == false {
            return []
        }

        do {
            return try Git.run("status --porcelain | awk '{print $2}'", path: path, verbose: verbose)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .filter({ $0.count > 0 })
                .map {
                    File.fromLine($0.trimmingCharacters(in: .whitespacesAndNewlines), path: path)
                }
        } catch _ {
            return []
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
