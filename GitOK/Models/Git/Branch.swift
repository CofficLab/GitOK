import Foundation
import SwiftData
import SwiftUI
import OSLog

struct Branch {
    static var label = "🌿 Branch::"
    
    var name: String
    var isCurrent = false

    static func fromShellLine(_ l: String, verbose: Bool = false) -> Branch {
        if verbose {
            os_log("\(self.label)Init from shell line -> \(l)")
        }
        
        return Branch(name: l.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                   .trimmingCharacters(in: .whitespacesAndNewlines),
               isCurrent: l.hasPrefix("*"))
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
