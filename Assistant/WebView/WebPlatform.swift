import Foundation
import OSLog
import SwiftUI
import WebKit

class WebPlatform {
    #if os(iOS)
        typealias ViewRepresentable = UIViewRepresentable
    #elseif os(macOS)
        typealias ViewRepresentable = NSViewRepresentable
    #endif
}

#Preview("APP") {
    AppPreview()
}
