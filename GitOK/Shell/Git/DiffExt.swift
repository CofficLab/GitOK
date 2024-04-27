import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查
    
    static func diffOfFile(_ path: String, file: File) throws -> String {
        try Git.run("diff HEAD~1 -- \(file.name)", path: path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
