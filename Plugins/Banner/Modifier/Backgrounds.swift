import MagicCore
import SwiftUI
import OSLog

/**
    背景选择器
    以网格形式展示所有可用的背景渐变，用户可以点击选择并切换背景。
    
    ## 功能特性
    - 网格布局显示背景选项
    - 当前选中状态的视觉反馈
    - 响应式布局适应不同屏幕尺寸
    - 流畅的交互体验
**/
struct Backgrounds: View {
    @Binding var current: String
    
    /// 网格列数，根据容器宽度自适应
    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0 ..< MagicBackgroundGroup.all.count, id: \.self) { index in
                    let gradient = MagicBackgroundGroup.all[index]
                    makeItem(gradient)
                        .frame(width: 60, height: 60)
                }
            }
            .padding(12)
        }
        .frame(minHeight: 120, maxHeight: 300)
    }

    /**
        创建单个背景选项
        
        ## 参数
        - `gradient`: 渐变背景类型
        
        ## 返回值
        返回可点击的背景选项视图
    */
    func makeItem(_ gradient: MagicBackgroundGroup.GradientName) -> some View {
        Button(action: {
            current = gradient.rawValue
        }) {
            ZStack {
                MagicBackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                if current == gradient.rawValue {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(current == gradient.rawValue ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: current)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
