import Foundation
import GitOKCoreKit
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
