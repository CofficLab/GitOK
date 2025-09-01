import MagicCore
import SwiftUI

/**
 * 可缩放的Banner布局组件
 * 专门用于截图导出，支持任意尺寸的Banner渲染
 * 与BannerLayout不同，这个组件会根据给定的尺寸动态调整布局
 */
struct ScalableBannerLayout: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    let targetWidth: CGFloat
    let targetHeight: CGFloat
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    var device: Device { b.banner.getDevice() }
    
    /// 计算缩放比例
    private var scaleRatio: CGFloat {
        let originalWidth = device.width
        let originalHeight = device.height
        
        let widthRatio = targetWidth / originalWidth
        let heightRatio = targetHeight / originalHeight
        
        // 使用较小的比例确保内容完全适应目标尺寸
        return min(widthRatio, heightRatio)
    }

    var body: some View {
        ZStack {
            switch Device(rawValue: b.banner.device) {
            case .iMac, .MacBook:
                HStack(spacing: 0) {
                    VStack(spacing: 0, content: {
                        Spacer()
                        VStack(spacing: 50 * scaleRatio) {
                            BannerTextEditor(banner: bannerBinding, isTitle: true)
                            BannerTextEditor(banner: bannerBinding, isTitle: false)
                        }
                        .frame(height: targetHeight / 3)
                        Features(features: featuresBinding)
                        Spacer()
                    })
                    .frame(width: targetWidth / 3)

                    BannerImage(banner: bannerBinding)
                        .padding(.horizontal, 50 * scaleRatio)
                        .frame(width: targetWidth / 3 * 2)
                        .frame(maxHeight: .infinity)
                }
            case .iPhoneSmall, .iPhoneBig:
                VStack(spacing: 40 * scaleRatio, content: {
                    BannerTextEditor(banner: bannerBinding, isTitle: true)
                    BannerTextEditor(banner: bannerBinding, isTitle: false)
                    Spacer()
                    BannerImage(banner: bannerBinding)
                        .frame(maxHeight: .infinity)
                })
            case .iPad, .none:
                VStack(spacing: 30 * scaleRatio) {
                    BannerTextEditor(banner: bannerBinding, isTitle: true)
                    BannerTextEditor(banner: bannerBinding, isTitle: false)
                    Spacer()
                    BannerImage(banner: bannerBinding)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .background(BannerBackground(banner: bannerBinding))
        .frame(width: targetWidth, height: targetHeight)
        .clipped() // 确保内容不会溢出
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
                    m.error(error)
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
    
    // MARK: - 私有方法
    
    /// 更新Banner数据的通用方法
    /// - Parameter update: 更新操作的闭包
    private func updateBanner(_ update: (inout BannerData) -> Void) {
        var updatedBanner = b.banner
        update(&updatedBanner)
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error(error)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
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
    .frame(width: 1200)
    .frame(height: 1200)
}
