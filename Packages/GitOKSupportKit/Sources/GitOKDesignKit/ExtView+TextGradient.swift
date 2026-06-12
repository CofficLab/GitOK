import GitOKFoundationKit
import SwiftUI

/// View扩展 - 提供Magic文字渐变色的便捷方法
public extension View {
    /// 为文字添加渐变色效果
    ///
    /// 使用这个方法可以轻松为任何文字视图添加渐变色效果
    /// 支持多种渐变方向和预设颜色组合
    ///
    /// ```swift
    /// Text("Hello World")
    ///     .magicGradient(colors: [.blue, .purple])
    /// ```
    ///
    /// - Parameters:
    ///   - colors: 渐变色数组，至少需要2个颜色
    ///   - startPoint: 渐变起始点，默认为leading
    ///   - endPoint: 渐变结束点，默认为trailing
    /// - Returns: 带有渐变色的文字视图
    func magicGradient(
        colors: [Color],
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }

    /// 为文字添加水平渐变色效果（简化版本）
    ///
    /// 这是`magicGradient`的简化版本，专门用于水平渐变
    /// 适用于大多数常见的文字渐变需求
    ///
    /// ```swift
    /// Text("Hello World")
    ///     .magicGradient(colors: [.blue, .purple])
    /// ```
    ///
    /// - Parameter colors: 渐变色数组，至少需要2个颜色
    /// - Returns: 带有水平渐变色的文字视图
    func magicGradient(colors: [Color]) -> some View {
        magicGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 为文字添加预设的彩虹渐变色效果
    ///
    /// 使用预设的彩虹渐变色，从红色到紫色
    ///
    /// ```swift
    /// Text("Rainbow")
    ///     .magicRainbowGradient()
    /// ```
    ///
    /// - Returns: 带有彩虹渐变色的文字视图
    func magicRainbowGradient() -> some View {
        magicGradient(
            colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 为文字添加预设的蓝紫渐变色效果
    ///
    /// 使用预设的蓝紫渐变色，类似你提供的示例
    ///
    /// ```swift
    /// Text("Blue Purple")
    ///     .magicBluePurpleGradient()
    /// ```
    ///
    /// - Returns: 带有蓝紫渐变色的文字视图
    func magicBluePurpleGradient() -> some View {
        magicGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 为文字添加预设的日落渐变色效果
    ///
    /// 使用预设的日落渐变色，从橙色到粉色
    ///
    /// ```swift
    /// Text("Sunset")
    ///     .magicSunsetGradient()
    /// ```
    ///
    /// - Returns: 带有日落渐变色的文字视图
    func magicSunsetGradient() -> some View {
        magicGradient(
            colors: [.orange, .pink, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 为文字添加预设的海洋渐变色效果
    ///
    /// 使用预设的海洋渐变色，从蓝色到青色
    ///
    /// ```swift
    /// Text("Ocean")
    ///     .magicOceanGradient()
    /// ```
    ///
    /// - Returns: 带有海洋渐变色的文字视图
    func magicOceanGradient() -> some View {
        magicGradient(
            colors: [.blue, .cyan, .teal],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 为文字添加垂直渐变色效果
    ///
    /// 从顶部到底部的垂直渐变
    ///
    /// ```swift
    /// Text("Vertical")
    ///     .magicVerticalGradient(colors: [.blue, .purple])
    /// ```
    ///
    /// - Parameter colors: 渐变色数组，至少需要2个颜色
    /// - Returns: 带有垂直渐变色的文字视图
    func magicVerticalGradient(colors: [Color]) -> some View {
        magicGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 为文字添加对角线渐变色效果
    ///
    /// 从左上角到右下角的对角线渐变
    ///
    /// ```swift
    /// Text("Diagonal")
    ///     .magicDiagonalGradient(colors: [.blue, .purple])
    /// ```
    ///
    /// - Parameter colors: 渐变色数组，至少需要2个颜色
    /// - Returns: 带有对角线渐变色的文字视图
    func magicDiagonalGradient(colors: [Color]) -> some View {
        magicGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Fruit Inspired Gradients

    /// 为文字添加柠檬渐变色效果（明黄到淡黄）
    func magicLemonGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FFF44F"), Color(hex: "FFE066")]
        )
    }

    /// 为文字添加橙子渐变色效果（橙色到金黄）
    func magicOrangeGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF9500"), Color(hex: "FF5E3A")]
        )
    }

    /// 为文字添加草莓渐变色效果（深红到粉红）
    func magicStrawberryGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E8E")]
        )
    }

    /// 为文字添加蓝莓渐变色效果（深蓝到紫蓝）
    func magicBlueberryGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "4169E1"), Color(hex: "6B5CED")]
        )
    }

    /// 为文字添加葡萄渐变色效果（紫到深紫）
    func magicGrapeGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")]
        )
    }

    /// 为文字添加西瓜渐变色效果（红到绿）
    func magicWatermelonGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "98FB98")]
        )
    }

    /// 为文字添加桃子渐变色效果（粉到橙粉）
    func magicPeachGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FFDAB9"), Color(hex: "FFB6C1")]
        )
    }

    /// 为文字添加薄荷渐变色效果（清新的绿色）
    func magicMintGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "98FF98"), Color(hex: "00FF7F")]
        )
    }

    /// 为文字添加樱桃渐变色效果（鲜红到暗红）
    func magicCherryGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "DE3163"), Color(hex: "FF4040")]
        )
    }

    /// 为文字添加芒果渐变色效果（金黄到橙黄）
    func magicMangoGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")]
        )
    }

    // MARK: - Nature Inspired Gradients

    /// 为文字添加森林渐变色效果（深绿到浅绿）
    func magicForestGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "228B22"), Color(hex: "32CD32")]
        )
    }

    /// 为文字添加天空渐变色效果（天蓝到淡蓝）
    func magicSkyGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "87CEEB"), Color(hex: "B0E0E6")]
        )
    }

    /// 为文字添加极光渐变色效果（紫到粉到青）
    func magicAuroraGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "9B59B6"), Color(hex: "FF69B4"), Color(hex: "00CED1")]
        )
    }

    /// 为文字添加大地渐变色效果（深棕到浅棕）
    func magicEarthGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "8B4513"), Color(hex: "D2691E")]
        )
    }

    /// 为文字添加雪山渐变色效果（白到冰蓝）
    func magicSnowGradient() -> some View {
        magicGradient(
            colors: [Color.white, Color(hex: "E0FFFF")]
        )
    }

    /// 为文字添加沙漠渐变色效果（金黄到沙黄）
    func magicDesertGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "EDC9AF"), Color(hex: "F4A460")]
        )
    }

    /// 为文字添加火山渐变色效果（红到橙到黄）
    func magicVolcanoGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF4500"), Color(hex: "FF6347"), Color(hex: "FFD700")]
        )
    }

    /// 为文字添加竹子渐变色效果（翠绿到深绿）
    func magicBambooGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "7CFC00"), Color(hex: "228B22")]
        )
    }

    /// 为文字添加黄昏渐变色效果（橙红到紫）
    func magicDuskGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "9370DB")]
        )
    }

    /// 为文字添加黎明渐变色效果（粉到橙到黄）
    func magicDawnGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FFB6C1"), Color(hex: "FFA07A"), Color(hex: "FFD700")]
        )
    }

    /// 为文字添加珊瑚渐变色效果（粉红到橙红）
    func magicCoralGradient() -> some View {
        magicGradient(
            colors: [Color(hex: "FF7F50"), Color(hex: "FF6347")]
        )
    }
}

// MARK: - Preview

