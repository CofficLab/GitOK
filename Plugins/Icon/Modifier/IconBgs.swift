import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/**
    图标背景选择器组件
    
    提供水平滚动的背景选择器，支持自定义每个背景项的大小
**/
struct IconBgs: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// 背景项的大小
    /// - 默认值：36x36
    let itemSize: CGFloat
    
    /// 初始化方法
    /// - Parameter itemSize: 背景项的大小，默认为36
    init(itemSize: CGFloat = 36) {
        self.itemSize = itemSize
    }

    var body: some View {
        GroupBox {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0 ..< MagicBackgroundGroup.all.count, id: \.self) { index in
                        let gradient = MagicBackgroundGroup.all[index]
                        makeItem(gradient)
                            .frame(width: itemSize, height: itemSize)
                    }
                }
            }
        }
    }

    /**
        创建单个背景项
        
        ## 参数
        - `gradient`: 背景渐变的名称
        
        ## 返回值
        包含背景预览和选择状态的按钮视图
     */
    func makeItem(_ gradient: MagicBackgroundGroup.GradientName) -> some View {
        Button(action: {
            if var icon = self.i.currentData {
                do {
                    try icon.updateBackgroundId(gradient.rawValue)
                } catch {
                    m.error(error.localizedDescription)
                }
            } else {
                m.error("先选择一个图标文件")
            }
        }) {
            ZStack {
                MagicBackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if self.i.currentData?.backgroundId == gradient.rawValue {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
