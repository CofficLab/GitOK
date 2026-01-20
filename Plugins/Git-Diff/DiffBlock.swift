import Foundation
import SwiftUI

struct DiffBlock {
    var block = ""
    
    static func fromBlock(_ b: String) -> DiffBlock {
        DiffBlock(block: b)
    }
    
    func getDiffs() -> [Diff] {
        block.components(separatedBy: "\n")
            .map({
                Diff.fromLine($0)
            })
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
