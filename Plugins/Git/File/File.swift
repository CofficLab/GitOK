import Foundation
import SwiftData
import SwiftUI

struct File {
    static var empty = File(projectPath: "", name: "")
    
    var projectPath: String
    var name: String
    var type: ChangeType = .modified
    
    var lastContent: String {
        do {
            return try GitShell.getFileLastContent(projectPath, file: name)
        } catch _ {
            return ""
        }
    }
    
    func getContent() throws -> String {
        try Shell().getFileContent(projectPath.appending("/").appending(name))
    }
    
    func originalContentOfCommit(_ commit: GitCommit) -> String {
        do {
            return try GitShell.run("show \(commit.hash)^:\(name)", path: projectPath)
        } catch _ {
            return ""
        }
    }
    
    func contentOfCommit(_ commit: GitCommit) -> String {
        do {
            return try GitShell.run("show \(commit.hash):\(name)", path: projectPath)
        } catch _ {
            return ""
        }
    }
    
    static func fromLine(_ l: String, path: String) -> File {
        let ll = l.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ll.hasPrefix("A") {
            return File(projectPath: path, name: l, type: .add)
        }
        
        if ll.hasPrefix("M") {
            return File(projectPath: path, name: l, type: .modified)
        }
        
        return File(projectPath: path, name: l)
    }
}

extension File: Hashable {
    static func ==(lhs: File, rhs: File) -> Bool {
        lhs.id == rhs.id
    }
}

extension File: Identifiable {
    var id: String {
        projectPath + name
    }
}

extension File {
    enum ChangeType {
        case modified
        case add
        case delete
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
