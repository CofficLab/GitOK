import Foundation
import OSLog
import SwiftUI

extension Git {
    func getBranches(_ path: String, verbose: Bool = false) throws -> [Branch] {
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
                    Branch.fromShellLine($0, path: path)
                }
        } catch let error {
            os_log(.error, "\(error.localizedDescription)")

            throw error
        }

        if verbose {
            os_log("\(self.t)GetBranches")
            print(branches)
        }

        return branches
    }

    func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        let verbose = false

        if verbose {
            os_log("\(self.t)GetCurrentBranch -> \(path)")
        }

        return Branch.fromShellLine(try run("branch --show-current", path: path, verbose: verbose), path: path)
    }

    @discardableResult
    func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        let result = try run("checkout \(b.name) -q", path: path, verbose: verbose)
        
        self.emitGitBranchChanged(branch: b.name)
        
        return result
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
