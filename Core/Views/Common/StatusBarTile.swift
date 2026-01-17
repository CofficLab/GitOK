import MagicKit
import SwiftUI

/// 通用状态栏 Tile：统一 hover 背景、内边距与形状。
struct StatusBarTile<Content: View>: View {
  /// 鼠标悬停状态
  @State private var hovered = false

  /// 图标名称
  let icon: String?

  /// 点击回调
  let onTap: (() -> Void)?

  /// 内容构建器
  let content: () -> Content

  /// 初始化状态栏 Tile
  /// - Parameters:
  ///   - icon: 系统图标名称
  ///   - onTap: 点击回调
  ///   - content: 内容构建器
  init(
    icon: String? = nil, onTap: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content
  ) {
    self.icon = icon
    self.onTap = onTap
    self.content = content
  }

  /// 视图主体
  var body: some View {
    HStack {
      if let icon {
        Image(systemName: icon)
      }
      content()
        .font(.footnote)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 8)
    .frame(maxHeight: .infinity, alignment: .center)
    .clipShape(RoundedRectangle(cornerRadius: 0))
    .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
    .contentShape(Rectangle())
    .onTapGesture {
      onTap?()
    }
    .onHover { hovering in
      hovered = hovering
    }
  }
}

/// StatusBarTile 的便捷初始化扩展
extension StatusBarTile where Content == EmptyView {
  /// 初始化只有图标的状态栏 Tile
  /// - Parameters:
  ///   - icon: 系统图标名称
  ///   - onTap: 点击回调
  init(icon: String? = nil, onTap: (() -> Void)? = nil) {
    self.init(icon: icon, onTap: onTap) { EmptyView() }
  }
}

// MARK: - Preview

#Preview("App - Small Screen") {
  ContentLayout()
    .hideSidebar()
    .hideTabPicker()
    .hideProjectActions()
    .inRootView()
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
  ContentLayout()
    .hideSidebar()
    .hideTabPicker()
    .inRootView()
    .frame(width: 1200)
    .frame(height: 1200)
}
