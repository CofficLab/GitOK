import Foundation
import SwiftUI

// MARK: JS 调用 Swift 时的通道名称

enum WebChannel {
    case pageLoaded
    case downloadFile
    case unknown(_ s: String)

    static func from(_ s: String) -> Self {
        switch s {
        case "pageLoaded":
            return .pageLoaded
        case "downloadFile":
            return .downloadFile
        default:
            return .unknown(s)
        }
    }

    var name: String {
        String(describing: self)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
