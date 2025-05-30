import Foundation
import SwiftData
import SwiftUI
import OSLog
import MagicCore

struct Branch: SuperLog {
    var emoji = "🌿"
    
    var path: String
    var name: String
    var isCurrent = false

    static func fromShellLine(_ l: String, path: String) -> Branch {
        let verbose = false
        if verbose {
            os_log("Init Branch from shell line -> \(l)")
        }
        
        return Branch(path: path, name: l.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                   .trimmingCharacters(in: .whitespacesAndNewlines),
               isCurrent: l.hasPrefix("*"))
    }
}

extension Branch: Hashable {
    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.name == rhs.name && lhs.path == rhs.path
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
