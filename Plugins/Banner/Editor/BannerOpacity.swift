import SwiftUI

struct BannerOpacity: View {
    @Binding var banner: BannerModel
    
    var body: some View {
        VStack {
            Slider(value: $banner.opacity, in: 0 ... 1)
                .padding()
        }
        .padding()
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

#Preview {
    RootView {
        Content()
    }
}
