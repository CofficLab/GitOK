import Foundation
import SwiftData
import SwiftUI

struct File {
    var name: String
    var type: ChangeType = .modified
    var uuid: String
    
    static func fromLine(_ l: String) -> File {
        let ll = l.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ll.hasPrefix("A") {
            return File(name: l, type: .add, uuid: UUID().uuidString)
        }
        
        if ll.hasPrefix("M") {
            return File(name: l, type: .modified, uuid: UUID().uuidString)
        }
        
        return File(name: l, uuid: UUID().uuidString)
    }
}

extension File: Hashable {
    static func ==(lhs: File, rhs: File) -> Bool {
        lhs.name == rhs.name
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
