import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

/**
    图标提供者，统一管理所有图标相关的状态和数据
    
    ## 主要职责
    - 管理当前选中的图标模型
    - 管理当前选中的图标ID
    - 处理图标的保存和删除事件
    - 提供图标选择状态
    
    ## 使用场景
    - 在图标选择器中选择图标时
    - 在图标编辑器中显示当前图标
    - 在图标列表中高亮显示选中的图标
    
    ## 注意事项
    - 所有图标状态变更都应该通过IconProvider进行
    - 避免在其他地方直接修改图标状态
    - 使用@Published属性确保UI能够响应状态变化
 */
class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var snapshotTapped: Bool = false
    @Published private(set) var currentModel: IconModel? = nil

    static var emoji = "🍒"

    /// 当前从候选列表中选中的图标ID
    /// 用于在图标选择器中高亮显示选中的图标
    @Published var selectedIconId: Int = 0
    
    /// 当前选中的图标分类
    /// 用于在分类标签页中高亮显示当前分类
    @Published var selectedCategory: String = ""
    
    /// 所有可用的图标分类
    @Published private(set) var availableCategories: [String] = []

    override init() {
        super.init()
        
        // 初始化可用分类
        self.availableCategories = IconPng.getCategories()
        if !availableCategories.isEmpty {
            self.selectedCategory = availableCategories.first!
        }
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIconDidSave),
            name: .iconDidSave,
            object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIconDidDelete),
            name: .iconDidDelete,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleIconDidSave(_ notification: Notification) {
        let iconPath = self.currentModel?.path
        if let iconPath = iconPath {
            let newModel = try? IconModel.fromJSONFile(URL(fileURLWithPath: iconPath))
            self.updateCurrentModel(newModel: newModel, reason: "iconDidSave event")
        }
    }

    @objc private func handleIconDidDelete(_ notification: Notification) {
        let path = notification.userInfo?["path"] as? String
        if let path = path, path == self.currentModel?.path {
            self.currentModel = nil
        }
    }

    func updateCurrentModel(newModel: IconModel?, reason: String) {
        os_log("\(self.t)Update Current Model(\(reason)) ➡️ \(newModel?.title ?? "nil")")

        self.currentModel = newModel
    }
    
    /**
        选择图标
        
        ## 参数
        - `iconId`: 要选择的图标ID
        
        ## 功能
        - 更新选中的图标ID
        - 如果当前有图标模型，同时更新模型的图标ID
        - 触发UI更新，显示高亮状态
     */
    func selectIcon(_ iconId: Int) {
        self.selectedIconId = iconId
        
        // 如果当前有图标模型，同时更新模型
        if var model = self.currentModel {
            do {
                try model.updateIconId(iconId)
            } catch {
                os_log(.error, "\(self.t)Failed to update model iconId: \(error)")
            }
        }
    }
    
    /**
        选择图标分类
        
        ## 参数
        - `category`: 要选择的分类名称
        
        ## 功能
        - 更新选中的分类
        - 触发UI更新，显示分类标签页的高亮状态
     */
    func selectCategory(_ category: String) {
        if availableCategories.contains(category) {
            self.selectedCategory = category
        }
    }
    
    /**
        刷新可用分类列表
        
        ## 功能
        - 重新扫描图标目录
        - 更新可用分类列表
        - 如果当前选中的分类不存在，自动选择第一个可用分类
     */
    func refreshCategories() {
        let newCategories = IconPng.getCategories()
        self.availableCategories = newCategories
        
        // 如果当前选中的分类不存在，选择第一个
        if !newCategories.contains(selectedCategory) && !newCategories.isEmpty {
            self.selectedCategory = newCategories.first!
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab("Icon")
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .setInitialTab("Icon")
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
