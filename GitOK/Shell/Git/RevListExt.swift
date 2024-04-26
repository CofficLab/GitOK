import Foundation
import OSLog
import SwiftUI

extension Git {
    static func revList(_ path: String) -> String {
        Git.run("rev-list HEAD ^origin/dev", path: path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
