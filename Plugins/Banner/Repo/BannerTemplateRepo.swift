import Foundation
import MagicKit
import OSLog
import SwiftUI

/**
 Banner模板仓库
 代理到BannerTemplateRegistry，提供统一的模板管理接口
 */
class BannerTemplateRepo: SuperLog {
    static let shared = BannerTemplateRepo()
    static var emoji = "📋"
    
    private let registry = BannerTemplateRegistry.shared
    
    private init() {}
    
    /// 获取所有可用模板
    func getAllTemplates() -> [any BannerTemplateProtocol] {
        return registry.getAllTemplates()
    }
    
    /// 根据ID获取模板
    func getTemplate(by id: String) -> (any BannerTemplateProtocol)? {
        return registry.getTemplate(by: id)
    }
    
    /// 获取默认模板
    func getDefaultTemplate() -> any BannerTemplateProtocol {
        return registry.getDefaultTemplate()
    }
    
    /// 添加新模板（为将来扩展预留）
    func addTemplate(_ template: any BannerTemplateProtocol) {
        os_log(.info, "\(Self.emoji) 添加新模板: \(template.name)")
        registry.register(template)
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
