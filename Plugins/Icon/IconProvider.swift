import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

/**
    图标提供者，统一管理所有图标插件相关的状态
 */
class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published private(set) var currentModel: IconModel? = nil

    static var emoji = "🍒"

    /// 当前从候选列表中选中的图标ID
    /// 用于在图标选择器中高亮显示选中的图标
    @Published var selectedIconId: String = ""
    
    /// 当前选中的分类
    @Published var selectedCategory: UnifiedIconCategory?
    
    /// 所有可用的分类
    @Published var availableCategories: [UnifiedIconCategory] = []
    
    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        return selectedCategory?.name ?? ""
    }

    override init() {
        super.init()
        
        os_log("\(self.t)Initializing IconProvider")
        
        // 初始化时加载分类
        refreshCategories()
        
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
        // 只有在图标真正保存时才更新模型，避免参数调整时的频繁更新
        let iconPath = self.currentModel?.path
        if let iconPath = iconPath {
            let newModel = try? IconModel.fromJSONFile(URL(fileURLWithPath: iconPath))
            // 只在模型真正发生变化时才更新
            if let newModel = newModel, newModel.path != self.currentModel?.path {
                self.updateCurrentModel(newModel: newModel, reason: "iconDidSave event")
            }
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
     */
    func selectIcon(_ iconId: String) {
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
     */
    func selectCategory(_ category: UnifiedIconCategory) {
        self.selectedCategory = category
    }
    
    /**
        刷新可用分类列表
     */
    func refreshCategories() {
        Task {
            let categories = await IconRepo.shared.getAllCategories()
            await MainActor.run {
                self.availableCategories = categories
                
                // 如果当前选中的分类不存在，选择第一个
                if let selected = selectedCategory,
                   !categories.contains(where: { $0.id == selected.id }) {
                    selectedCategory = categories.first
                }
                
                // 如果没有选中的分类，选择第一个
                if selectedCategory == nil && !categories.isEmpty {
                    selectedCategory = categories.first
                }
            }
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> UnifiedIconCategory? {
        return availableCategories.first { $0.name == name }
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
    .frame(height: 800)
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
