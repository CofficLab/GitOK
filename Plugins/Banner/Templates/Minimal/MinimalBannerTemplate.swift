import SwiftUI

/**
 简约模板
 居中简洁的布局风格
 */
struct MinimalBannerTemplate: BannerTemplateProtocol {
    let id = "minimal"
    let name = "简约风格"
    let description = "居中布局，简洁优雅"
    let systemImageName = "rectangle.center.inset.filled"
    
    func createPreviewView(device: Device) -> AnyView {
        AnyView(
            MinimalBannerLayout(device: device)
                .environmentObject(BannerProvider.shared)
        )
    }
    
    func createModifierView() -> AnyView {
        AnyView(MinimalBannerModifiers())
    }
    
    func createExampleView() -> AnyView {
        AnyView(MinimalBannerExampleView())
    }
    
    func getDefaultData() -> Any {
        return MinimalBannerData()
    }
}

/**
 简约模板的数据模型
 */
struct MinimalBannerData {
    var title: String = "App Title"
    var subtitle: String = "Simple and Clean"
    var backgroundId: String = "1"
    var opacity: Double = 1.0
    var titleColor: Color? = nil
    var subtitleColor: Color? = nil
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
