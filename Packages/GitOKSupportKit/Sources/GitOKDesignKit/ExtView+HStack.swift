import GitOKFoundationKit
import SwiftUI

/// View扩展 - 提供Magic HStack布局的便捷方法
public extension View {
    /// 将视图包装在HStack中并居中显示
    ///
    /// 使用这个方法可以将任何SwiftUI View包装在HStack中，并自动添加Spacer来使内容水平居中
    /// 支持自定义间距和对齐方式
    ///
    /// ```swift
    /// Text("Hello World")
    ///     .inMagicHStackCenter()
    /// ```
    ///
    /// - Parameters:
    ///   - spacing: HStack中元素之间的间距，默认为nil（使用系统默认间距）
    ///   - alignment: 垂直对齐方式，默认为center
    ///   - leadingSpacer: 是否在左侧添加Spacer，默认为true
    ///   - trailingSpacer: 是否在右侧添加Spacer，默认为true
    /// - Returns: 包装在HStack中并居中的视图
    func inMagicHStackCenter(
        spacing: CGFloat? = nil,
        alignment: VerticalAlignment = .center,
        leadingSpacer: Bool = true,
        trailingSpacer: Bool = true
    ) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            if leadingSpacer {
                Spacer()
            }

            self

            if trailingSpacer {
                Spacer()
            }
        }
    }

    /// 将视图包装在HStack中并居中显示（简化版本）
    ///
    /// 这是`inMagicHStackCenter`的简化版本，使用默认参数
    /// 适用于大多数常见的居中布局需求
    ///
    /// ```swift
    /// Text("Hello World")
    ///     .inMagicHStackCenter()
    /// ```
    ///
    /// - Returns: 包装在HStack中并居中的视图
    func inMagicHStackCenter() -> some View {
        inMagicHStackCenter(
            spacing: nil,
            alignment: .center,
            leadingSpacer: true,
            trailingSpacer: true
        )
    }
}

// MARK: - Preview

