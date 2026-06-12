import SwiftUI


/**
 经典模板的副标题组件
 专门为经典布局设计的副标题显示组件
 */
struct ClassicSubTitle: View {
    @EnvironmentObject var b: BannerProvider

    var fontSize: CGFloat = 48

    init(fontSize: CGFloat = 48) {
        self.fontSize = fontSize
    }

    var classicData: ClassicBannerData? { b.banner.classicData }

    var body: some View {
        Text(classicData?.subTitle ?? "Banner SubTitle")
            .font(.system(size: fontSize, weight: .medium, design: .default))
            .foregroundColor(getSubTitleColor())
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }

    private func getSubTitleColor() -> Color {
        return classicData?.subTitleColor ?? .secondary
    }
}
