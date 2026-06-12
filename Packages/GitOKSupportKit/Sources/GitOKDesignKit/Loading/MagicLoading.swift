import GitOKFoundationKit
import SwiftUI

/// 一个简化的加载状态视图组件
///
/// `MagicLoading` 提供了一个简洁的加载状态展示视图，支持可选的 logo 视图、标题和进度指示器。
///
/// 基本使用示例：
/// ```swift
/// // 使用默认样式
/// MagicLoading()
///
/// // 使用自定义标题
/// MagicLoading("同步中...")
///
/// // 不显示进度指示器
/// MagicLoading("准备中...", showProgress: false)
///
/// // 使用自定义 logo
/// MagicLoading("同步中...") {
///     Image("logo")
///         .resizable()
///         .frame(width: 60, height: 60)
/// }
///
/// // 使用自定义 logo 且不显示进度指示器
/// MagicLoading("准备中...", showProgress: false) {
///     Image("logo")
///         .resizable()
///         .frame(width: 60, height: 60)
/// }
/// ```
public struct MagicLoading<LogoView: View>: View {
    // MARK: - Properties
    
    private let title: String
    private let showProgress: Bool
    private let logoView: (() -> LogoView)?
    
    // MARK: - Initialization
    
    /// 创建一个加载状态视图
    /// - Parameters:
    ///   - title: 显示的文本标题，默认为"加载中..."
    ///   - showProgress: 是否显示进度指示器，默认为 true
    public init(_ title: String = "加载中...", showProgress: Bool = true) where LogoView == EmptyView {
        self.title = title
        self.showProgress = showProgress
        self.logoView = nil
    }
    
    /// 创建一个带有自定义 logo 的加载状态视图
    /// - Parameters:
    ///   - title: 显示的文本标题，默认为"加载中..."
    ///   - showProgress: 是否显示进度指示器，默认为 true
    ///   - logoView: 自定义 logo 视图构建器
    public init(
        _ title: String = "加载中...",
        showProgress: Bool = true,
        @ViewBuilder logoView: @escaping () -> LogoView
    ) {
        self.title = title
        self.showProgress = showProgress
        self.logoView = logoView
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 12) {
            if let logoView {
                logoView()
            }
            
            if showProgress {
                ProgressView()
                    .controlSize(.regular)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

