import GitOKFoundationKit
import SwiftUI

/// View扩展 - 分隔线相关
public extension View {
    /// 将视图与分隔线包装在VStack中
    ///
    /// 使用这个方法可以在视图下方添加一个分隔线
    /// 主要用于列表项的分隔或内容分区
    ///
    /// ```swift
    /// Text("Hello")
    ///     .withDivider()
    /// ```
    ///
    /// - Returns: 包装在VStack中的视图和分隔线
    func withDivider() -> some View {
        VStack(spacing: 0) {
            self
            Divider()
        }
    }

    /// 将视图与分隔线包装在VStack中，并指定间距
    ///
    /// ```swift
    /// Text("Hello")
    ///     .withDivider(spacing: 10)
    /// ```
    ///
    /// - Parameter spacing: 视图与分隔线之间的间距
    /// - Returns: 包装在VStack中的视图和分隔线
    func withDivider(spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            self
            Divider()
        }
    }

    /// 将视图与自定义分隔线包装在VStack中
    ///
    /// ```swift
    /// Text("Hello")
    ///     .withDivider {
    ///         Rectangle()
    ///             .fill(.blue)
    ///             .frame(height: 2)
    ///     }
    /// ```
    ///
    /// - Parameter divider: 自定义分隔线视图构建器
    /// - Returns: 包装在VStack中的视图和分隔线
    func withDivider<DividerContent: View>(
        @ViewBuilder divider: () -> DividerContent
    ) -> some View {
        VStack(spacing: 0) {
            self
            divider()
        }
    }

    /// 将视图与自定义分隔线（带间距）包装在VStack中
    ///
    /// ```swift
    /// Text("Hello")
    ///     .withDivider(spacing: 10) {
    ///         Rectangle()
    ///             .fill(.blue)
    ///             .frame(height: 2)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - spacing: 视图与分隔线之间的间距
    ///   - divider: 自定义分隔线视图构建器
    /// - Returns: 包装在VStack中的视图和分隔线
    func withDivider<DividerContent: View>(
        spacing: CGFloat,
        @ViewBuilder divider: () -> DividerContent
    ) -> some View {
        VStack(spacing: spacing) {
            self
            divider()
        }
    }
}

// MARK: - Preview

