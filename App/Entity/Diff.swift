import Foundation
import SwiftUI

struct Diff {
    var message = ""
    var uuid: String
    
    static func fromLine(_ l: String) -> Diff {
        Diff(message: l, uuid: UUID().uuidString)
    }
}

extension Diff: Identifiable {
    var id: String {
        uuid
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
