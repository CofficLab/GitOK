import MagicCore
import MagicAlert
import SwiftUI

/**
 经典模板的副标题编辑器
 专门为经典布局定制的副标题编辑组件
 */
struct ClassicSubTitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State private var subTitleText: String = ""
    @State private var subTitleColor: Color = .secondary

    var body: some View {
        GroupBox("副标题设置") {
            VStack(spacing: 12) {
                // 副标题输入
                HStack {
                    Text("副标题")
                        .frame(width: 60, alignment: .leading)

                    TextField("输入副标题", text: $subTitleText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: subTitleText) {
                            updateSubTitle()
                        }
                }

                // 副标题颜色选择
                HStack {
                    Text("颜色")
                        .frame(width: 60, alignment: .leading)

                    ColorPicker("选择颜色", selection: $subTitleColor)
                        .labelsHidden()
                        .onChange(of: subTitleColor) {
                            updateSubTitleColor()
                        }

                    Spacer()
                }
            }
            .padding(8)
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        if let classicData = b.banner.classicData {
            subTitleText = classicData.subTitle
            subTitleColor = classicData.subTitleColor ?? .secondary
        }
    }

    private func updateSubTitle() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.subTitle = subTitleText
            banner.classicData = classicData
        }
    }

    private func updateSubTitleColor() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.subTitleColor = subTitleColor
            banner.classicData = classicData
        }
    }
}

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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
