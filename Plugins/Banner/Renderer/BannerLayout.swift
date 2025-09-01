import MagicCore
import SwiftUI

/**
    Banner布局渲染器
    根据不同设备类型渲染Banner布局，直接从BannerProvider获取和修改数据。
    
    ## 功能特性
    - 支持多种设备类型布局
    - 实时编辑文本和图片
    - 动态调节透明度
    - 边框显示辅助功能
    - 自动保存更改
**/
struct BannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @Binding var showBorder: Bool
    @State private var showOpacityToolbar: Bool = false
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    var device: Device { b.banner.getDevice() }

    var body: some View {
        ZStack {
            switch Device(rawValue: b.banner.device) {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50) {
                            BannerTextEditor(banner: bannerBinding, isTitle: true)
                            BannerTextEditor(banner: bannerBinding, isTitle: false)
                        }
                        .frame(height: device.height / 3)
                        Features(features: featuresBinding)
                        Spacer()
                    })
                    .frame(width: device.width / 3)
                    .overlay(
                        showBorder ? Rectangle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 20, dash: [5]))
                            .foregroundColor(.red) : nil
                    )

                    BannerImage(banner: bannerBinding)
                        .padding(.horizontal, 50)
                        .frame(width: device.width / 3 * 2)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 20, dash: [5]))
                                .foregroundColor(.yellow) : nil
                        )
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40, content: {
                    BannerTextEditor(banner: bannerBinding, isTitle: true)
                    BannerTextEditor(banner: bannerBinding, isTitle: false)
                    Spacer()
                    BannerImage(banner: bannerBinding)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.black) : nil
                        )
                })
            case .iPad, .none:
                GeometryReader { _ in
                    BannerTextEditor(banner: bannerBinding, isTitle: true)
                    BannerTextEditor(banner: bannerBinding, isTitle: false)
                    Spacer()
                    BannerImage(banner: bannerBinding)
                        .overlay(
                            showBorder ? Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.black) : nil
                        )
                }
            }
        }
        .background(BannerBackground(banner: bannerBinding))
        .onTapGesture {
            showOpacityToolbar.toggle()
        }
        .overlay(
            showOpacityToolbar ? VStack {
                Slider(value: Binding(
                    get: { b.banner.opacity },
                    set: { newOpacity in
                        updateBanner { banner in
                            banner.opacity = newOpacity
                        }
                    }
                ), in: 0...1)
                    .frame(width: 200)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                Spacer()
            } : nil
        )
    }
    
    // MARK: - 计算属性
    
    /// Banner数据Binding
    private var bannerBinding: Binding<BannerData> {
        Binding(
            get: { b.banner },
            set: { newBanner in
                b.setBanner(newBanner)
                
                // 保存到磁盘
                do {
                    try bannerRepo.saveBanner(newBanner)
                } catch {
                    m.error("保存Banner失败：\(error.localizedDescription)")
                }
            }
        )
    }
    
    /// Features数据Binding
    private var featuresBinding: Binding<[String]> {
        Binding(
            get: { b.banner.features },
            set: { newFeatures in
                updateBanner { banner in
                    banner.features = newFeatures
                }
            }
        )
    }
    
    /**
        更新Banner数据
        提供一个修改闭包来更新Banner的属性，并自动保存到磁盘
        
        ## 参数
        - `modifier`: 修改Banner属性的闭包
    */
    private func updateBanner(_ modifier: (inout BannerData) -> Void) {
        guard b.banner != .empty else { return }
        
        var updatedBanner = b.banner
        modifier(&updatedBanner)
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存Banner失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - Event Handlers

extension BannerLayout {
   
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
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
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
