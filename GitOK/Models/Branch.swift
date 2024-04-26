import Foundation
import SwiftData
import SwiftUI

struct Branch {
    var name: String

    init(_ name: String) {
        self.name = name
    }
    
    static func fromShellLine(_ l: String) -> Branch {
        Branch(l.trimmingCharacters(in: CharacterSet(charactersIn: "*")).trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

extension Branch: Hashable {
    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.name == rhs.name
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
