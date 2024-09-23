import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查
    
    func getFileContent(_ path: String, file: String) throws -> String {
        try run("cat \(file)", path: path)
    }
    
    func getFileLastContent(_ path: String, file: String) throws -> String {
        try run("show --textconv HEAD:\(file)", path: path, verbose: false)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
