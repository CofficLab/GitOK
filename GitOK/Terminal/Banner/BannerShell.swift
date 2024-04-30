import Foundation
import OSLog
import SwiftUI

class BannerShell {
    static var root: String = ".gitok/banners"
    static var label: String = "🔮 BannerShell "

    static func new(_ name: String, path: String, verbose: Bool = false) {
        let dir = "\(path)/\(root)"
        let fullPath = "\(dir)/\(name).json"
        Shell.makeDir(dir)
        Shell.makeFile(fullPath)
    }
}

#Preview {
    AppPreview()
}
