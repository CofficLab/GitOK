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
    static var emoji = "🍒"
    
    @Published private(set) var currentData: IconData? = nil

    /// 当前从候选列表中选中的图标ID
    /// 用于在图标选择器中高亮显示选中的图标
    @Published var selectedIconId: String = ""
    
    /// 当前选中的分类
    @Published var selectedCategory: IconCategoryInfo?
    

    
    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        return selectedCategory?.name ?? ""
    }

    override init() {
        super.init()
        
        os_log("\(self.t)Initializing IconProvider")
        
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
        let iconPath = self.currentData?.path
        if let iconPath = iconPath {
            let newModel = try? IconData.fromJSONFile(URL(fileURLWithPath: iconPath))
            // 只在模型真正发生变化时才更新
            if let newModel = newModel, newModel.path != self.currentData?.path {
                self.updateCurrentModel(newModel: newModel)
            }
        }
    }

    @objc private func handleIconDidDelete(_ notification: Notification) {
        let path = notification.userInfo?["path"] as? String
        if let path = path, path == self.currentData?.path {
            self.currentData = nil
        }
    }

    func updateCurrentModel(newModel: IconData?) {
        self.currentData = newModel
        self.selectedIconId = newModel?.iconId ?? ""
    }
    
    /**
        选择图标
     */
    func selectIcon(_ iconId: String) {
        self.selectedIconId = iconId
        
        // 如果当前有图标模型，同时更新模型
        if var model = self.currentData {
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
    func selectCategory(_ category: IconCategoryInfo?) {
        self.selectedCategory = category
    }
    
    /**
        清空选中的分类
     */
    func clearSelectedCategory() {
        self.selectedCategory = nil
    }

}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
