import MagicCore
import SwiftUI

/**
     Banner编辑器
     提供Banner的可视化编辑和预览功能，支持缩放、截图等操作。
     直接从BannerProvider获取数据，通过事件通知处理截图操作。

     ## 功能特性
     - 实时编辑预览
     - 手势缩放支持
     - 事件驱动的截图功能
     - 自适应布局调整
     - 异步加载优化
 **/
struct BannerEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var showBorder: Bool = false
    @State var visible = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    @MainActor private var imageSize: String {
        "\(MagicImage.getViewWidth(content)) X \(MagicImage.getViewHeigth(content))"
    }

    var body: some View {
        bodyBanner
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
        .onBannerSnapshot {
            handleSnapshot()
        }
    }

    var viewBody: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
                .alignmentGuide(HorizontalAlignment.center) { _ in geo.size.width / 2 }
                .alignmentGuide(VerticalAlignment.center) { _ in geo.size.height / 2 }
                .scaleEffect(min(geo.size.width / b.banner.getDevice().width, geo.size.height / b.banner.getDevice().height) * scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
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
        BannerLayout()
            .frame(width: b.banner.getDevice().width)
            .frame(height: b.banner.getDevice().height)
            .environmentObject(BannerProvider.shared)
    }

    /// 处理截图事件
    private func handleSnapshot() {
        guard g.project != nil else {
            m.error("没有选中的项目")
            return
        }

        let result = MagicImage.snapshot(content)

        m.success(result)
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
