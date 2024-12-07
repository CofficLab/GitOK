import MagicKit
import SwiftUI

struct BannerEditor: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @Binding var banner: BannerModel
    
    @State var showBorder: Bool = false
    @State var snapshotTapped: Bool = false
    @State var visible = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    @MainActor private var imageSize: String {
        "\(ImageHelper.getViewWidth(content)) X \(ImageHelper.getViewHeigth(content))"
    }

    var body: some View {
        VStack {
            BannerTopBar(
                snapshotTapped: $snapshotTapped,
                banner: $banner,
                showBorder: $showBorder
            )

            GroupBox {
                bodyBanner
            }.padding()
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }

    var bodyBanner: some View {
        // 异步加载banner，加快响应速度
        ZStack {
            if !visible {
                ProgressView()
                    .onAppear {
                        visible = true
                    }
            }

            if visible {
                viewBody
            }
        }
        .onChange(of: snapshotTapped, {
            if snapshotTapped {
                m.toast(ImageHelper.snapshot(content, title: "\(banner.device)-\(self.getTimeString())"))
                self.snapshotTapped = false
            }
        })
    }

    var viewBody: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
                .alignmentGuide(HorizontalAlignment.center) { _ in geo.size.width / 2 }
                .alignmentGuide(VerticalAlignment.center) { _ in geo.size.height / 2 }
                .scaleEffect(min(geo.size.width / banner.getDevice().width, geo.size.height / banner.getDevice().height) * scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { value in
                            lastScale = scale
                        }
                )
        }
        .padding()
    }

    var imageBody: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                ImageHelper.makeImage(content)
                    .resizable()
                    .scaledToFit()
                    .padding(.all, 20)
                Spacer()
            }
            Spacer()
        }
    }

    private var content: some View {
        BannerLayout(banner: $banner, showBorder: $showBorder)
            .frame(width: banner.getDevice().width)
            .frame(height: banner.getDevice().height)
    }

    private func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
}

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var showBorder: Bool = true
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
                BannerEditor(
                    banner: $previewBanner
                )
            }
            .frame(width: 500)
            .frame(height: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("APP") {
    AppPreview()
        .frame(width: 500)
        .frame(height: 500)
}
