import Foundation
import SwiftUI

// MARK: - Minimal Template

extension BannerFile {
    /// 获取简约模板数据
    var minimalData: MinimalBannerData? {
        get {
            BannerTemplateDataStore.decode(
                MinimalBannerData.self,
                templateID: MinimalBannerData.templateId,
                from: templateData
            )
        }
        set {
            BannerTemplateDataStore.updateEncoded(
                newValue,
                templateID: MinimalBannerData.templateId,
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
