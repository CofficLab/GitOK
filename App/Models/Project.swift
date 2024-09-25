import Foundation
import SwiftData
import SwiftUI
import OSLog

@Model
final class Project {
    static var verbose = true
    static var null = Project(URL(fileURLWithPath: ""))
    static var orderReverse = [
        SortDescriptor<Project>(\.timestamp, order: .reverse)
    ]
    
    var label: String { "🌳 Project::" }
    var timestamp: Date
    var url: URL
    
    @Transient
    var git = Git()
    
    var title: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
    
    var headCommit: GitCommit {
        GitCommit.headFor(path)
    }
    
    var isGit: Bool {
        git.isGitProject(path: path)
    }
    
    var isNotGit: Bool { !isGit }
    
    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }
    
    func getCommits(_ reason: String) -> [GitCommit] {
        let verbose = false
        
        if verbose {
            os_log("\(self.label)GetCommit(\(reason))")
        }
        
        do {
            return try git.logs(path)
        } catch let error {
            os_log(.error, "\(self.label)GetCommits has error")
            os_log(.error, "\(error)")
            
            return []
        }
    }
    
    func getCommitsWithHead(_ reason: String) -> [GitCommit] {
        if Self.verbose {
            os_log("\(self.label)GetCommitWithHead with reason->\(reason)")
        }
        
        return [self.headCommit] + getCommits(reason)
    }

    func hasUnCommittedChanges() -> Bool {
        git.hasUnCommittedChanges(path: path)
    }

    func getBanners() throws -> [BannerModel] {
        let verbose = false
        
        if verbose {
            os_log("\(self.label)GetBanners for project -> \(self.path)")
        }
        
        return try BannerModel.all(self)
    }

    func getIcons() throws -> [IconModel] {
        let verbose = false
        
        if verbose {
            os_log("\(self.label)GetIcons for project -> \(self.path)")
        }
        
        return try IconModel.all(self.path)
    }

    func isExist() -> Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
}

extension Project: Identifiable {
    var id: URL {
        self.url
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}