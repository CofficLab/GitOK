import SwiftUI
import MagicCore

/**
    边框切换按钮组件
    提供Banner边框显示/隐藏切换功能的独立按钮组件，支持选中状态显示。
    
    ## 功能特性
    - 边框显示状态的可视化反馈
    - 切换边框显示/隐藏功能
    - 选中状态的视觉指示
    - 一致的UI风格和交互体验
**/
struct BorderToggleButton: View {
    /// 当前边框显示状态
    @Binding var showBorder: Bool
    
    var body: some View {
        MagicButton.simple(
            icon: "square.dashed", 
            title: "边框",
            action: {
                showBorder.toggle()
            }
        )
    }
}

/**
    便捷初始化方法
    提供更简洁的创建方式
**/
extension BorderToggleButton {
    /// 创建边框切换按钮
    /// - Parameter showBorder: 边框显示状态绑定
    /// - Returns: 边框切换按钮视图
    static func create(showBorder: Binding<Bool>) -> BorderToggleButton {
        BorderToggleButton(showBorder: showBorder)
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
