import SwiftUI

struct BannerTitle: View {
    @State var isEditingTitle = false

    @Binding var banner: BannerModel

    var body: some View {
        if isEditingTitle {
            GeometryReader { geo in
                TextField("", text: $banner.title)
                    .font(.system(size: 200))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .frame(width: geo.size.width)
                    .onSubmit {
                        self.isEditingTitle = false
                    }
            }
        } else {
            Text(banner.title)
                .font(.system(size: 200))
                .foregroundColor(.white)
                .onTapGesture {
                    self.isEditingTitle = true
                }
        }
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
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
