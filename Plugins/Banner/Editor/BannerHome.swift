import SwiftUI
import MagicKit

struct BannerHome: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @Binding var banner: BannerModel
    
    @State var snapshotTapped: Bool = false
    @State var visible = false

    @MainActor private var imageSize: String {
        "\(ImageHelper.getViewWidth(content)) X \(ImageHelper.getViewHeigth(content))"
    }

    var body: some View {
        VStack {
            BannerTopBar(snapshotTapped: $snapshotTapped, banner: $banner)

            GroupBox {
                bodyBanner
            }.padding()
        }
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
                m.setFlashMessage(ImageHelper.snapshot(content, title: "\(banner.device)-\(self.getTimeString())"))
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
                .scaleEffect(min(geo.size.width / banner.getDevice().width, geo.size.height / banner.getDevice().height))
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
        BannerLayout(banner: $banner)
            .frame(width: banner.getDevice().width)
            .frame(height: banner.getDevice().height)
    }

    private func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
