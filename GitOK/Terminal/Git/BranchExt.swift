import Foundation
import OSLog
import SwiftUI

extension Git {
    func getBranches(_ path: String, verbose: Bool = false) -> [Branch] {
        if self.isGitProject(path: path) == false {
            return []
        }

        var branches: [Branch] = []

        do {
            branches = try run("branch", path: path)
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
            os_log("\(self.label)GetBranches")
            print(branches)
        }

        return branches
    }

    func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        Branch.fromShellLine(try run("branch --show-current", path: path, verbose: verbose))
    }

    func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        try run("checkout \(b.name) -q", path: path, verbose: verbose)
    }

    func merge(
        _ from: Branch,
        _ path: String,
        verbose: Bool = false,
        message: String = "merge"
    ) throws {
        _ = try run("merge \(from.name) -m '\(message)'", path: path, verbose: verbose)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
