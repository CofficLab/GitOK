import SwiftUI

/**
 经典布局模板
 左侧文字，右侧图片的布局
 */
struct ClassicBannerTemplate: BannerTemplateProtocol {
    let id = "classic"
    let name = "经典布局"
    let description = "左侧标题副标题和特性，右侧产品图片"
    let systemImageName = "rectangle.split.2x1"
    
    func createPreviewView() -> AnyView {
        AnyView(
            ClassicBannerLayout()
                .environmentObject(BannerProvider.shared)
        )
    }
    
    func createModifierView() -> AnyView {
        AnyView(ClassicBannerModifiers())
    }
    
    func createExampleView() -> AnyView {
        AnyView(ClassicBannerExampleView())
    }
    
    func getDefaultData() -> Any {
        return ClassicBannerData()
    }
    
    func restoreData(from bannerData: BannerFile) -> Any {
        // 经典模板目前使用通用字段，不需要额外的模板特定数据
        return ClassicBannerData(
            title: bannerData.title,
            subTitle: bannerData.subTitle,
            features: bannerData.features,
            imageId: bannerData.imageId,
            backgroundId: bannerData.backgroundId,
            inScreen: bannerData.inScreen,
            opacity: bannerData.opacity,
            titleColor: bannerData.titleColor,
            subTitleColor: bannerData.subTitleColor
        )
    }
    
    func saveData(_ templateData: Any, to bannerData: inout BannerFile) throws {
        guard let classicData = templateData as? ClassicBannerData else {
            throw BannerError.invalidTemplateData
        }
        
        bannerData.title = classicData.title
        bannerData.subTitle = classicData.subTitle
        bannerData.features = classicData.features
        bannerData.imageId = classicData.imageId
        bannerData.backgroundId = classicData.backgroundId
        bannerData.inScreen = classicData.inScreen
        bannerData.opacity = classicData.opacity
        bannerData.titleColor = classicData.titleColor
        bannerData.subTitleColor = classicData.subTitleColor
        
        // 经典模板目前不需要额外的模板特定数据存储
        bannerData.templateData = nil
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

