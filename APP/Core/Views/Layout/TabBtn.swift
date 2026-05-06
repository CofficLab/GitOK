import MagicKit
import OSLog
import SwiftUI

/// 标签页按钮视图
struct TabBtn: View, SuperLog {
  /// emoji 标识符
  nonisolated static let emoji = "🔘"

  /// 是否启用详细日志输出
  nonisolated static let verbose = false

  /// 鼠标悬停状态
  @State private var hovered: Bool = false

  /// 按钮点击状态
  @State private var isButtonTapped = false

  /// 显示提示状态
  @State private var showTips: Bool = false

  /// 按钮标题
  var title: String

  /// 图标名称
  var imageName: String

  /// 是否选中状态
  var selected = false

  /// 点击回调
  var onTap: () -> Void = {
    os_log("Tab button tapped")
  }

  /// 视图主体
  var body: some View {
    Label(
      title: {
        Text(title)
      },
      icon: {
        Image(systemName: imageName)
          .resizable()
          .scaledToFit()
      }
    )
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(hovered || selected ? Color.gray.opacity(0.4) : .clear)
    .clipShape(RoundedRectangle(cornerRadius: 0))
    .onHover(perform: { hovering in
      withAnimation(.easeInOut) {
        hovered = hovering
      }
    })
    .onTapGesture {
      withAnimation(.default) {
        onTap()
      }
    }
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
