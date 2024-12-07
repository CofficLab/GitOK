import SwiftUI
import MagicKit

struct BannerBackground: View {
    @Binding var banner: BannerModel

    var body: some View {
        BackgroundGroup(for:banner.backgroundId)
            .opacity(banner.opacity)
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
    }
}

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var previewBanner = BannerModel(
            title: "制作海报",
            subTitle: "简单又快捷",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: ""
        )

        var body: some View {
            RootView {
                BannerEditor(banner: $previewBanner)
            }
            .frame(width: 500)
            .frame(height: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("App") {
    RootView {
        Content()
    }
    .frame(height: 800)
    .frame(width: 800)
}

#Preview("App-2") {
    RootView {
        Content()
    }
    .frame(height: 1200)
    .frame(width: 800)
}
