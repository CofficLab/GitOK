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
                Branch.fromShellLine($0)
            }
    }
    
    static func setBranch(_ b: Branch, _ path: String, debugPrint: Bool = false) -> String {
        Git.run("checkout \(b.name)", path: path, debugPrint: debugPrint)
    }
    
    static func merge(_ from: Branch, _ path: String, debugPrint: Bool = false) -> String {
        Git.run("merge \(from.name)", path: path, debugPrint: debugPrint)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
