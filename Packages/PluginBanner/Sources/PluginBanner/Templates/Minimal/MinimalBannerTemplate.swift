import SwiftUI

/**
 简约布局模板
 居中简洁的布局风格
 */
struct MinimalBannerTemplate: BannerTemplateProtocol {
    let id = "minimal"
    let name = String(localized: "Minimal Style", table: "Banner")
    let description = String(localized: "Centered layout, clean and elegant", table: "Banner")
    let systemImageName = "rectangle.center.inset.filled"

    @MainActor
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

    func getDefaultData() -> MinimalBannerData {
        return MinimalBannerData()
    }

    func restoreData(from bannerData: BannerFile) -> MinimalBannerData {
        // 从模板数据中恢复
        if let minimalData = bannerData.minimalData {
            return minimalData
        }

        // 如果没有数据，返回默认值
        return getDefaultData()
    }

    func saveData(_ templateData: Any, to bannerData: inout BannerFile) throws {
        guard let minimalData = templateData as? MinimalBannerData else {
            throw BannerError.invalidTemplateData
        }

        // 保存模板数据
        bannerData.minimalData = minimalData
    }
}
