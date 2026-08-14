import SwiftUI

/// 颜色扩展，提供从十六进制字符串创建颜色的功能
extension Color {
    /// 使用十六进制字符串初始化颜色
    ///
    /// 支持以下格式的十六进制字符串:
    /// - 3位RGB格式: 例如 "F00"（等同于 "FF0000"）
    /// - 6位RGB格式: 例如 "FF0000"
    /// - 8位ARGB格式: 例如 "FFFF0000"
    ///
    /// - Parameter hex: 表示颜色的十六进制字符串，可以包含或不包含前缀 "#"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
