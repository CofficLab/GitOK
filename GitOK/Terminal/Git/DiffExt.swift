import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查

    func diffOfFile(_ path: String, file: File) throws -> DiffBlock {
        DiffBlock(block: try run("diff HEAD~1 -- \(file.name)", path: path))
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
