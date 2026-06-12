import SwiftUI

/**
 经典Banner模板的修改器视图
 包含经典布局所需的所有独立编辑控件
 */
struct ClassicBannerModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ClassicTitleEditor()
                ClassicSubTitleEditor()
                ClassicFeaturesEditor()
                ClassicImageEditor()
                ClassicBackgroundEditor()
                ClassicOpacityEditor()
            }
            .padding()
        }
    }
}
