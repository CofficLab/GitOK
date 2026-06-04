import OSLog
import MagicAlert
import GitOKSupportKit
import GitOKCoreKit
import SwiftUI

/**
    图标背景选择器组件

    提供水平滚动的背景选择器，支持自定义每个背景项的大小
**/
struct IconBgs: View {
    @EnvironmentObject var i: IconProvider


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
        AppSelectionTile(
            isSelected: self.i.currentData?.backgroundId == gradient.rawValue,
            cornerRadius: 8,
            selectedBorderColor: .red,
            action: {
                if var icon = self.i.currentData {
                    do {
                        try icon.updateBackgroundId(gradient.rawValue)
                    } catch {
                        os_log(.error, "❌ 更新图标背景失败: \(error.localizedDescription)")
                        alert_error(error.localizedDescription)
                    }
                } else {
                    os_log(.error, "❌ 未选择图标文件")
                    alert_error("先选择一个图标文件")
                }
            }
        ) {
            MagicBackgroundGroup(for: gradient)
        }
    }
}
