import SwiftUI
import MagicCore

/**
    截图按钮组件
    提供Banner截图功能的独立按钮组件，通过事件通知机制触发截图操作。
    
    ## 功能特性
    - 简洁的截图图标和标题
    - 通过事件通知触发截图
    - 一致的UI风格
    - 易于集成和重用
    - 解耦合的事件驱动设计
**/
struct SnapshotButton: View {
    var body: some View {
        MagicButton.simple(
            icon: "camera.aperture", 
            title: "截图",
            action: {
                // 发送截图事件通知
                NotificationCenter.default.post(name: .bannerSnapshot, object: nil)
            }
        )
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
    .frame(width: 1200)
    .frame(height: 1200)
}