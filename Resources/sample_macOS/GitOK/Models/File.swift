import Foundation
import SwiftData
import SwiftUI

struct File {
    var name: String
    var type: ChangeType = .modified
    
    static func fromLine(_ l: String) -> File {
        let ll = l.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ll.hasPrefix("A") {
            return File(name: l, type: .add)
        }
        
        if ll.hasPrefix("M") {
            return File(name: l, type: .modified)
        }
        
        return File(name: l)
    }
}

extension File: Hashable {
    static func ==(lhs: File, rhs: File) -> Bool {
        lhs.name == rhs.name
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
