import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查
    
    func show(_ path: String, hash: String) throws -> String {
        try run("show \(hash)", path: path)
    }
    
    func commitFiles(_ path: String, hash: String) throws -> [File] {
        try run("show \(hash) --pretty='' --name-only", path: path)
            .components(separatedBy: "\n")
            .map({
                File.fromLine($0, path: path)
            })
    }
    
    func add(_ path: String, verbose: Bool = false) throws {
        let message = try run("add -A .", path: path)
        
        if verbose {
            os_log("\(self.label)Add -> \(message)")
        }
    }

    func commit(_ path: String, commit: String) throws -> String {
        try run("commit -a -m '\(commit)'", path: path)
    }
    
    func commitAndPush(_ message: String, path: String) throws {
        DispatchQueue.main.async {
            do {
                // 检查是否通过HTTPS进行push
                let shell = Shell()
                let remoteUrl = try shell.run("git config --get remote.origin.url", at: path)
                if remoteUrl.starts(with: "https://") {
                    // Git凭据缓存
                    let cacheResult = shell.configureGitCredentialCache()
                    os_log("\(shell.label)Configure Git Credential Cache -> \(cacheResult)")
                    
                    // 检查HTTPS凭据
                    let commit = GitCommit.headFor(path)
                    guard commit.checkHttpsCredentials() else {
                        os_log(.error, "HTTPS 凭据未配置")
                        throw GitError.credentialsNotConfigured
                    }
                }

                do {
                    try shell.run("git add .", at: path)
                    try shell.run("git commit -m \"\(message)\"", at: path)
                } catch let error {
                    os_log(.error, "提交失败: \(error.localizedDescription)")
                    throw error
                }

                try self.push(path)
            } catch let error {
                os_log(.error, "commitAndPush 失败: \(error.localizedDescription)")
            }
        }
    }

    func getShortHash(_ path: String, _ hash: String) throws -> String {
        try run("rev-parse --short", path: path)
    }

    func log(_ path: String) throws -> String {
        try run("log", path: path)
    }

    func logs(_ path: String) throws -> [GitCommit] {
        try run("log --pretty=format:%H+%s", path: path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    func notSynced(_ path: String) throws -> [GitCommit] {
        try revList(path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
