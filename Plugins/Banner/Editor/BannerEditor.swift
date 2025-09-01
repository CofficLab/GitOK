import MagicCore
import SwiftUI

struct BannerEditor: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider

    @Binding var banner: BannerData
    
    @State var showBorder: Bool = false
    @State var snapshotTapped: Bool = false
    @State var visible = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    @MainActor private var imageSize: String {
        "\(MagicImage.getViewWidth(content)) X \(MagicImage.getViewHeigth(content))"
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
                m.info(MagicImage.snapshot(content, title: "\(banner.device)-\(self.getTimeString())"))
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
                MagicImage.makeImage(content)
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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(BannerPlugin.label)
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1000)
}

