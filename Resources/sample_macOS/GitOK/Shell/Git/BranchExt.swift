import Foundation
import OSLog
import SwiftUI

extension Git {
    static func getBranches(_ path: String) -> [Branch] {
        Git.run("branch", path: path)
            .components(separatedBy: "\n")
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter({
                $0.count != 0
            })
            .map {
                Branch($0)
            }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
