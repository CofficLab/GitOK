import Foundation
import OSLog
import SwiftUI

extension Git {
    static func getBranches(_ path: String, verbose: Bool = false) -> [Branch] {
        if Git.isGitProject(path: path) == false {
            return []
        }

        var branches: [Branch] = []

        do {
            branches = try Git.run("branch", path: path)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
                .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter({
                    $0.count != 0
                })
                .map {
                    Branch.fromShellLine($0)
                }
        } catch let error { }

        if verbose {
            os_log("\(label)GetBranches")
            print(branches)
        }

        return branches
    }

    static func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        Branch.fromShellLine(try Git.run("branch --show-current", path: path, verbose: verbose))
    }

    static func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        try Git.run("checkout \(b.name) -q", path: path, verbose: verbose)
    }

    static func merge(
        _ from: Branch,
        _ path: String,
        verbose: Bool = false,
        message: String = "merge"
    ) throws {
        _ = try Git.run("merge \(from.name) -m '\(message)'", path: path, verbose: verbose)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
