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
    
    /// 当前选中的图标分类
    @Published var selectedCategory: IconCategory?
    
    /// 当前是否使用远程仓库
    @Published var isUsingRemoteRepo: Bool = false
    
    /// 当前选中的远程分类ID（用于远程分类的高亮显示）
    @Published var selectedRemoteCategoryId: String = ""
    
    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        if isUsingRemoteRepo {
            return selectedRemoteCategoryId
        } else {
            return selectedCategory?.name ?? ""
        }
    }
    
    /// 所有可用的图标分类名称（兼容性属性）
    var availableCategories: [String] {
        // 根据当前仓库类型返回相应的分类
        if isUsingRemoteRepo {
            // 这里暂时返回空数组，因为需要异步获取
            return []
        } else {
            return IconRepo.shared.getAllCategories().map { $0.name }
        }
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
    func selectCategory(_ category: IconCategory) {
        self.selectedCategory = category
    }
    
    /**
        选择远程图标分类
     */
    func selectRemoteCategory(_ categoryId: String) {
        self.selectedRemoteCategoryId = categoryId
    }
    
    /**
        刷新可用分类列表
     */
    func refreshCategories() {
        if isUsingRemoteRepo {
            // 使用远程仓库
            Task {
                let remoteCategories = await RemoteIconRepo().getAllCategories()
                await MainActor.run {
                    // 选择第一个远程分类作为默认选中
                    if let firstRemoteCategory = remoteCategories.first {
                        selectedRemoteCategoryId = firstRemoteCategory.id
                    }
                }
            }
        } else {
            // 使用本地仓库
            let allCategories = IconRepo.shared.getAllCategories()

            // 如果当前选中的分类不存在，选择第一个
            if let selected = selectedCategory,
               !allCategories.contains(where: { $0.id == selected.id }) {
                selectedCategory = allCategories.first
            }
            
            // 如果没有选中的分类，选择第一个
            if selectedCategory == nil && !allCategories.isEmpty {
                selectedCategory = allCategories.first
            }
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> IconCategory? {
        IconRepo.shared.getCategory(byName: name)
    }
    
    /// 切换仓库类型
    func toggleRepository() {
        isUsingRemoteRepo.toggle()
        // 刷新分类列表
        refreshCategories()
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
