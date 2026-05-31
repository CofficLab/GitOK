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
