import SwiftUI

/**
 简约布局模板
 居中简洁的布局风格
 */
struct MinimalBannerTemplate: BannerTemplateProtocol {
    let id = "minimal"
    let name = "简约风格"
    let description = "居中布局，简洁优雅"
    let systemImageName = "rectangle.center.inset.filled"
    
    func createPreviewView() -> AnyView {
        AnyView(
            MinimalBannerLayout()
                .environmentObject(BannerProvider.shared)
        )
    }
    
    func createModifierView() -> AnyView {
        AnyView(MinimalBannerModifiers())
    }
    
    func createExampleView() -> AnyView {
        AnyView(MinimalBannerExampleView())
    }
    
    func getDefaultData() -> Any {
        return MinimalBannerData()
    }
    
    func restoreData(from bannerData: BannerFile) -> Any {
        // 简约模板目前使用通用字段，不需要额外的模板特定数据
        return MinimalBannerData(
            title: bannerData.title,
            imageId: bannerData.imageId,
            backgroundId: bannerData.backgroundId,
            inScreen: bannerData.inScreen,
            opacity: bannerData.opacity,
            titleColor: bannerData.titleColor
        )
    }
    
    func saveData(_ templateData: Any, to bannerData: inout BannerFile) throws {
        guard let minimalData = templateData as? MinimalBannerData else {
            throw BannerError.invalidTemplateData
        }
        
        bannerData.title = minimalData.title
        bannerData.imageId = minimalData.imageId
        bannerData.backgroundId = minimalData.backgroundId
        bannerData.inScreen = minimalData.inScreen
        bannerData.opacity = minimalData.opacity
        bannerData.titleColor = minimalData.titleColor
        
        // 简约模板目前不需要额外的模板特定数据存储
        bannerData.templateData = nil
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


