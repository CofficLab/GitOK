import Foundation
import SwiftUI

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
    func createPreviewView(device: Device) -> AnyView
    
    /// 创建修改器视图
    func createModifierView() -> AnyView
    
    /// 创建示例视图（用于模板选择器）
    func createExampleView() -> AnyView
    
    /// 获取模板的默认数据
    func getDefaultData() -> Any
}

/**
 经典布局模板
 左侧文字，右侧图片的布局
 */
struct ClassicBannerTemplate: BannerTemplateProtocol {
    let id = "classic"
    let name = "经典布局"
    let description = "左侧标题副标题和特性，右侧产品图片"
    let systemImageName = "rectangle.split.2x1"
    
    func createPreviewView(device: Device) -> AnyView {
        AnyView(
            ClassicBannerLayout(device: device)
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
}

/**
 经典布局的数据模型
 */
struct ClassicBannerData {
    var title: String = "Banner Title"
    var subTitle: String = "Banner SubTitle"
    var features: [String] = []
    var imageId: String? = nil
    var backgroundId: String = "1"
    var inScreen: Bool = false
    var opacity: Double = 1.0
    var titleColor: Color? = nil
    var subTitleColor: Color? = nil
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
