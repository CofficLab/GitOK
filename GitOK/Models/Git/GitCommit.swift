import Foundation
import SwiftUI
import OSLog

struct GitCommit {
    static var headId = "HEAD"
    static var empty = GitCommit()
    static func headFor(_ path: String) -> GitCommit {
        .init(isHead: true, path: path, hash: Self.headId, message: "当前")
    }

    var path: String
    var isHead = false
    var hash: String
    var message: String
    
    var label: String {
        "\(Logger.isMain)🌊 GitCommit::"
    }
    
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
    
    func checkIfSynced() throws -> Bool {
        if isHead {
            return true
        }
        
        do {
            return try !Git().notSynced(path).contains(where: {
                $0.hash == self.hash
            })
        } catch let error {
            return true
        }
    }
    
    func getFiles() -> [File] {
        os_log("\(self.label)GetFiles->\(path)")
        if isHead {
            return Git().changedFile(path)
        } else {
            do {
                return try Git().commitFiles(path, hash: hash)
            } catch (let e) {
                os_log(.error, "\(e.localizedDescription)")
                
                return []
            }
        }
    }
    
    func getTitle() -> String {
        if isHead == false {
            return message
        } else {
            let count = getFiles().count
            return "\(count) 个变动"
        }
    }
    
    // 新增方法：检查HTTPS凭据
    func checkHttpsCredentials() -> Bool {
        let command = "git config --get credential.helper"
        do {
            let result = try Shell().run(command)
            return !result.isEmpty
        } catch {
            os_log(.error, "检查HTTPS凭据时出错: \(error.localizedDescription)")
            return false
        }
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
