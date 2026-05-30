import SwiftUI

/**
 经典布局模板
 左侧文字，右侧图片的布局
 */
struct ClassicBannerTemplate: BannerTemplateProtocol {
    let id = "classic"
    let name = String(localized: "Classic Layout", table: "Banner")
    let description = String(localized: "Left: title, subtitle and features. Right: product image", table: "Banner")
    let systemImageName = "rectangle.split.2x1"

    @MainActor
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

    func getDefaultData() -> ClassicBannerData {
        return ClassicBannerData()
    }

    func restoreData(from bannerData: BannerFile) -> ClassicBannerData {
        // 从模板数据中恢复
        if let classicData = bannerData.classicData {
            return classicData
        }

        // 如果没有数据，返回默认值
        return getDefaultData()
    }

    func saveData(_ templateData: Any, to bannerData: inout BannerFile) throws {
        guard let classicData = templateData as? ClassicBannerData else {
            throw BannerError.invalidTemplateData
        }

        // 保存模板数据
        bannerData.classicData = classicData
    }
}
