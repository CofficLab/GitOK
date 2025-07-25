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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
