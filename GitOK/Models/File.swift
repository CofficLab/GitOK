import Foundation
import SwiftData
import SwiftUI

struct File {
    var projectPath: String
    var name: String
    var type: ChangeType = .modified
    var uuid: String
    
    var lastContent: String {
        do {
            return try Git.getFileLastContent(projectPath, file: name)
        } catch let error {
            return ""
        }
    }
    
    var content: String {
        do {
            return try Git.getFileContent(projectPath, file: name)
        } catch let error {
            return ""
        }
    }
    
    static func fromLine(_ l: String, path: String) -> File {
        let ll = l.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ll.hasPrefix("A") {
            return File(projectPath: path, name: l, type: .add, uuid: UUID().uuidString)
        }
        
        if ll.hasPrefix("M") {
            return File(projectPath: path, name: l, type: .modified, uuid: UUID().uuidString)
        }
        
        return File(projectPath: path, name: l, uuid: UUID().uuidString)
    }
}

extension File: Hashable {
    static func ==(lhs: File, rhs: File) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension File: Identifiable {
    var id: String {
        uuid
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
