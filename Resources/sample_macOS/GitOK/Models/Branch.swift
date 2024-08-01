import Foundation
import SwiftData
import SwiftUI

struct Branch {
    var name: String

    init(_ name: String) {
        self.name = name
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
