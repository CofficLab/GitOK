import Foundation
import SwiftUI
import AppKit

/// NSColor 扩展，提供转换为 SwiftUI Color 的功能
extension NSColor {
    /// 将 NSColor 转换为 SwiftUI 的 Color
    /// - Returns: SwiftUI Color 对象
    var asColor: Color {
        Color(nsColor: self)
    }
}