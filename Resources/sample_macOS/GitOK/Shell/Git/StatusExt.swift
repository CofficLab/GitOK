import Foundation
import OSLog
import SwiftUI

extension Git {
    static func status(_ path: String) -> String {
        Git.run("status", path: path)
    }

    static func changedFile(_ path: String) -> [File] {
        Git.run("status --porcelain", path: path)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .filter({ $0.count > 0 })
            .map {
                File.fromLine($0.trimmingCharacters(in: .whitespacesAndNewlines))
            }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
