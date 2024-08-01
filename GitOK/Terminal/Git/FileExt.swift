import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查
    
    static func getFileContent(_ path: String, file: String) throws -> String {
        try Shell.run("cd \(path) && cat \(file)", verbose: false)
    }
    
    static func getFileLastContent(_ path: String, file: String) throws -> String {
        try Git.run("show --textconv HEAD:\(file)", path: path, verbose: false)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
