import Foundation
import SwiftUI

// MARK: - Classic Template

extension BannerFile {
    /// 获取经典模板数据
    var classicData: ClassicBannerData? {
        get {
            guard let jsonString = getTemplateData(ClassicBannerData.templateId) else {
                return nil
            }
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                return nil
            }
            
            return try? JSONDecoder().decode(ClassicBannerData.self, from: jsonData)
        }
        set {
            guard let newValue = newValue else {
                templateData.removeValue(forKey: ClassicBannerData.templateId)
                return
            }
            
            guard let jsonData = try? JSONEncoder().encode(newValue),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return
            }
            
            try? setTemplateData(ClassicBannerData.templateId, data: jsonString)
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
