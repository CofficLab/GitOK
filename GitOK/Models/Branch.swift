import Foundation
import SwiftData
import SwiftUI

struct Branch {
    var uuid: String
    var name: String
    var isCurrent = false

    static func fromShellLine(_ l: String) -> Branch {
        Branch(uuid: UUID().uuidString,
               name: l.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                   .trimmingCharacters(in: .whitespacesAndNewlines),
               isCurrent: l.hasPrefix("*"))
    }
}

extension Branch: Hashable {
    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
