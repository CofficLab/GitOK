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

#Preview {
    AppPreview()
        .frame(width: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
