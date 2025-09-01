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
    func createPreviewView(device: Device) -> AnyView
    
    /// 创建修改器视图
    func createModifierView() -> AnyView
    
    /// 创建示例视图（用于模板选择器）
    func createExampleView() -> AnyView
    
    /// 获取模板的默认数据
    func getDefaultData() -> Any
    
    /// 从BannerData中恢复模板特定的数据
    func restoreData(from bannerData: BannerData) -> Any
    
    /// 将模板特定的数据保存到BannerData中
    func saveData(_ templateData: Any, to bannerData: inout BannerData) throws
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
    
    func restoreData(from bannerData: BannerData) -> Any {
        // 经典模板目前使用通用字段，不需要额外的模板特定数据
        return ClassicBannerData(
            title: bannerData.title,
            subTitle: bannerData.subTitle,
            features: bannerData.features,
            imageId: bannerData.imageId,
            backgroundId: bannerData.backgroundId,
            inScreen: bannerData.inScreen,
            opacity: bannerData.opacity,
            titleColor: bannerData.titleColor,
            subTitleColor: bannerData.subTitleColor
        )
    }
    
    func saveData(_ templateData: Any, to bannerData: inout BannerData) throws {
        guard let classicData = templateData as? ClassicBannerData else {
            throw BannerError.invalidTemplateData
        }
        
        bannerData.title = classicData.title
        bannerData.subTitle = classicData.subTitle
        bannerData.features = classicData.features
        bannerData.imageId = classicData.imageId
        bannerData.backgroundId = classicData.backgroundId
        bannerData.inScreen = classicData.inScreen
        bannerData.opacity = classicData.opacity
        bannerData.titleColor = classicData.titleColor
        bannerData.subTitleColor = classicData.subTitleColor
        
        // 经典模板目前不需要额外的模板特定数据存储
        bannerData.templateData = nil
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
