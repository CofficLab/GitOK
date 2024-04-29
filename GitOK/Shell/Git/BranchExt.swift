import Foundation
import OSLog
import SwiftUI

extension Git {
    static func getBranches(_ path: String) throws -> [Branch] {
        try Git.run("branch", path: path)
            .components(separatedBy: "\n")
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter({
                $0.count != 0
            })
            .map {
                Branch.fromShellLine($0)
            }
    }
    
    static func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        Branch.fromShellLine(try Git.run("branch --show-current", path: path, verbose: verbose))
    }

    static func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        try Git.run("checkout \(b.name) -q", path: path, verbose: verbose)
    }

    static func merge(_ from: Branch, _ path: String, verbose: Bool = false) throws -> String {
        try Git.run("merge \(from.name)", path: path, verbose: verbose)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
