import GitOKFoundationKit
import SwiftUI

/// View扩展 - 提供Magic ScrollView布局的便捷方法
public extension View {
    /// 将视图包装在ScrollView中
    ///
    /// 使用这个方法可以将任何SwiftUI View包装在ScrollView中，支持水平和垂直滚动
    /// 支持自定义滚动方向、显示滚动指示器等
    ///
    /// ```swift
    /// VStack {
    ///     Text("Content 1")
    ///     Text("Content 2")
    ///     // ... more content
    /// }
    ///     .inScrollView()
    /// ```
    ///
    /// - Parameters:
    ///   - axes: 滚动方向，默认为.vertical
    ///   - showsIndicators: 是否显示滚动指示器，默认为true
    ///   - contentInsets: 内容的内边距，默认为nil（无内边距）
    /// - Returns: 包装在ScrollView中的视图
    func inScrollView(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        contentInsets: EdgeInsets? = nil
    ) -> some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            if let insets = contentInsets {
                self.padding(insets)
            } else {
                self
            }
        }
    }

    /// 将视图包装在垂直ScrollView中（简化版本）
    ///
    /// 这是`inScrollView`的简化版本，专门用于垂直滚动
    /// 使用默认参数，适用于大多数常见的垂直滚动需求
    ///
    /// ```swift
    /// VStack {
    ///     ForEach(items) { item in
    ///         Text(item.title)
    ///     }
    /// }
    ///     .inScrollView()
    /// ```
    ///
    /// - Returns: 包装在垂直ScrollView中的视图
    func inScrollView() -> some View {
        inScrollView(
            axes: .vertical,
            showsIndicators: true,
            contentInsets: nil
        )
    }
}

// MARK: - Preview

