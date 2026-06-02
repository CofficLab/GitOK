import GitOKFoundationKit
import SwiftUI

// MARK: - View Extension for Poster

public extension View {
    /// 为视图添加海报副标题配置，当前视图将作为标题显示
    /// - Parameter subtitle: 副标题文本
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterSubTitle(_ subtitle: String?) -> PosterBuilder {
        var builder = PosterBuilder(titleView: AnyView(self))
        builder.subtitleTop = subtitle
        return builder
    }

    /// 直接生成海报视图，当前视图将作为标题显示
    /// - Returns: 配置好的 PosterContainer 视图
    func asPoster() -> some View {
        PosterContainer(
            titleView: { self },
            rightContent: { EmptyView() }
        )
    }

    /// 设置海报背景颜色
    /// - Parameter color: 背景颜色
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterBackground(_ color: Color) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterBackground(color)
    }

    /// 设置海报背景渐变
    /// - Parameters:
    ///   - colors: 渐变颜色数组
    ///   - startPoint: 渐变起始点
    ///   - endPoint: 渐变结束点
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterBackground(
        gradient colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterBackground(gradient: colors, startPoint: startPoint, endPoint: endPoint)
    }

    /// 设置海报背景材质
    /// - Parameter material: 材质类型
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterBackground(_ material: Material) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterBackground(material)
    }

    /// 设置自定义海报背景视图
    /// - Parameter content: 背景视图
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterBackground<Content: View>(_ content: Content) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterBackground(content)
    }

    /// 设置海报右侧内容
    /// - Parameter content: 右侧视图内容
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterRightContent<Content: View>(_ content: Content) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterRightContent(content)
    }

    /// 设置海报预览视图
    /// - Parameter content: 预览视图内容
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterPreview<Content: View>(_ content: Content) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterPreview(content)
    }

    /// 设置海报布局间距
    /// - Parameter spacing: 水平间距
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterSpacing(_ spacing: CGFloat) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterSpacing(spacing)
    }

    /// 设置海报标题字体大小
    /// - Parameter size: 字体大小
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterTitleFontSize(_ size: CGFloat) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterTitleFontSize(size)
    }

    /// 设置是否显示 Logo
    /// - Parameter show: 是否显示 Logo
    /// - Returns: PosterBuilder 实例，可继续链式调用
    func withPosterLogo(_ show: Bool) -> PosterBuilder {
        PosterBuilder(titleView: AnyView(self))
            .withPosterLogo(show)
    }
}

// MARK: - Preview

