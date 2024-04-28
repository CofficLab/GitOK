import Foundation
import OSLog
import SwiftUI

extension Git {
    static func status(_ path: String) throws -> String {
        try Git.run("status", path: path)
    }

    static func changedFile(_ path: String, debugPrint: Bool = true) throws -> [File] {
        try Git.run("status --porcelain | awk '{print $2}'", path: path, debugPrint: debugPrint)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .filter({ $0.count > 0 })
            .map {
                File.fromLine($0.trimmingCharacters(in: .whitespacesAndNewlines), path: path)
            }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
