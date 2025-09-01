import Foundation
import SwiftUI

/**
 Banner错误类型
 */
enum BannerError: Error, LocalizedError {
    case invalidTemplateData
    
    var errorDescription: String? {
        switch self {
        case .invalidTemplateData:
            return "无效的模板数据"
        }
    }
}

/**
 Banner模板协议
 定义每个模板必须实现的接口
 */
protocol BannerTemplateProtocol: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var systemImageName: String { get }
    
    /// 创建预览视图
    func createPreviewView() -> AnyView
    
    /// 创建修改器视图
    func createModifierView() -> AnyView
    
    /// 创建示例视图（用于模板选择器）
    func createExampleView() -> AnyView
    
    /// 获取模板的默认数据
    func getDefaultData() -> Any
    
    /// 从BannerData中恢复模板特定的数据
    func restoreData(from bannerData: BannerFile) -> Any
    
    /// 将模板特定的数据保存到BannerData中
    func saveData(_ templateData: Any, to bannerData: inout BannerFile) throws
}

/**
 模板注册表
 管理所有可用的模板
 */
class BannerTemplateRegistry {
    static let shared = BannerTemplateRegistry()
    
    private var templates: [any BannerTemplateProtocol] = []
    
    private init() {
        registerDefaultTemplates()
    }
    
    private func registerDefaultTemplates() {
        register(ClassicBannerTemplate())
        register(MinimalBannerTemplate())
        // 将来可以注册更多模板
        // register(ModernBannerTemplate())
    }
    
    func register(_ template: any BannerTemplateProtocol) {
        templates.append(template)
    }
    
    func getAllTemplates() -> [any BannerTemplateProtocol] {
        return templates
    }
    
    func getTemplate(by id: String) -> (any BannerTemplateProtocol)? {
        return templates.first { $0.id == id }
    }
    
    func getDefaultTemplate() -> any BannerTemplateProtocol {
        return ClassicBannerTemplate()
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
    .frame(width: 800)
    .frame(height: 1000)
}
