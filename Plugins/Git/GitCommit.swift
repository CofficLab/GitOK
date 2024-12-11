import Foundation
import SwiftUI
import OSLog
import MagicKit

struct GitCommit: SuperLog {
    static var headId = "HEAD"
    static var empty = GitCommit()
    static func headFor(_ path: String) -> GitCommit {
        .init(isHead: true, path: path, hash: Self.headId, message: String(localized: "current_head", bundle: .main))
    }

    var path: String
    var isHead = false
    var hash: String
    var message: String
    
    var emoji = "🌊"
    
    var isEmpty: Bool { self.path == "/" } 

    init(
        isHead: Bool = false,
        path: String = "/",
        hash: String = "",
        message: String = ""
    ) {
        self.isHead = isHead
        self.path = path
        self.hash = hash
        self.message = message
    }

    static func fromShellLine(_ l: String, path: String, seprator: String = "+") -> GitCommit {
        let components = l.components(separatedBy: seprator)
        let count = components.count
        let hash = count > 0 ? components[0] : ""
        let message = count > 1 ? components[1] : ""

        return GitCommit(path: path, hash: hash, message: message)
    }
    
    func checkIfSynced(_ branch: String) throws -> Bool {
        if isHead {
            return true
        }
        
        let command = "git rev-list --left-right --count \(hash)...origin/\(branch)"
        do {
            let result = try Shell().run(command, at: path)
            let components = result.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\t")
            
            if components.count == 2 {
                return components[0] == "" || components[0] == "0"
            }
            
            if components.count == 1 {
                return true
            }
            
            return false
        } catch {
            os_log(.error, "检查同步状态时出错: \(error.localizedDescription)")
            return false
        }
    }
    
    func getFiles(reason: String) -> [File] {
        let verbose = false

        if verbose {
            os_log("\(self.t)GetFiles")
            os_log("  🫧 Message: \(self.message)")
            os_log("  🫧 Path: \(path)")
            os_log("  🫧 Hash: \(hash)")
        }
        
        if isHead {
            return GitShell().changedFile(path)
        } else {
            do {
                return try GitShell().commitFiles(path, hash: hash)
            } catch (let e) {
                os_log(.error, "\(e.localizedDescription)")
                
                return []
            }
        }
    }
    
    func getTitle(reason: String) -> String {
        if isHead == false {
            return message
        } else {
            let count = getFiles(reason: "GitCommit.GetTitle").count
            return "\(count) 个变动"
        }
    }
    
    // 检查HTTPS凭据
    func checkHttpsCredentials() -> Bool {
        let command = "git config --get credential.helper"
        do {
            let result = try Shell().run(command)
            os_log("\(self.t)checkHttpsCredentials -> \(result)")
            return !result.isEmpty
        } catch {
            os_log(.error, "检查HTTPS凭据时出错: \(error.localizedDescription)")
            return false
        }
    }

    func getTag() throws -> String {
        try GitShell().getTag(path, hash)
    }
}

extension GitCommit: Identifiable {
    var id: String {
        path+hash
    }
}

extension GitCommit: Hashable {}

extension GitCommit {
    static var autoCommitMessage = "\(CommitCategory.Chore.text) Auto Commit"
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
