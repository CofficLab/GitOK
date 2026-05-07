import Foundation
import SwiftUI

// MARK: - Classic Template

extension BannerFile {
    /// 获取经典模板数据
    var classicData: ClassicBannerData? {
        get {
            BannerTemplateDataStore.decode(
                ClassicBannerData.self,
                templateID: ClassicBannerData.templateId,
                from: templateData
            )
        }
        set {
            BannerTemplateDataStore.updateEncoded(
                newValue,
                templateID: ClassicBannerData.templateId,
                in: &templateData
            )
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("Banner")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("Banner")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
