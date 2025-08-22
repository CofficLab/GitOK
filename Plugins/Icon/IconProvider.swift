import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

/**
    图标提供者，统一管理所有图标相关的状态和数据
 */
class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var snapshotTapped: Bool = false
    @Published private(set) var currentModel: IconModel? = nil

    static var emoji = "🍒"

    /// 当前从候选列表中选中的图标ID
    /// 用于在图标选择器中高亮显示选中的图标
    @Published var selectedIconId: Int = 0
    
    /// 所有可用的图标分类
    @Published private(set) var categories: [IconCategory] = []
    
    /// 当前选中的图标分类
    @Published var selectedCategory: IconCategory?
    
    /// 分类是否正在加载
    @Published private(set) var isLoadingCategories = false
    
    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        selectedCategory?.name ?? ""
    }
    
    /// 所有可用的图标分类名称（兼容性属性）
    var availableCategories: [String] {
        categories.map { $0.name }
    }

    override init() {
        super.init()
        
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
     */
    func selectCategory(_ category: String) {
        print("🎯 IconProvider: 选择分类 '\(category)'")
        if let categoryModel = categories.first(where: { $0.name == category }) {
            print("🎯 找到分类，设置为选中: \(categoryModel.name)")
            selectedCategory = categoryModel
        } else {
            print("🎯 未找到分类 '\(category)'")
        }
    }
    
    /**
        刷新可用分类列表
     */
    func refreshCategories() {
        isLoadingCategories = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newCategories = self?.loadCategories() ?? []
            
            DispatchQueue.main.async {
                self?.categories = newCategories
                self?.isLoadingCategories = false
                
                // 如果当前选中的分类不存在，选择第一个
                if let selected = self?.selectedCategory,
                   !newCategories.contains(where: { $0.name == selected.name }) {
                    self?.selectedCategory = newCategories.first
                }
                
                // 如果没有选中的分类，选择第一个
                if self?.selectedCategory == nil && !newCategories.isEmpty {
                    self?.selectedCategory = newCategories.first
                }
            }
        }
    }
    
    /// 加载分类列表
    /// - Returns: 分类数组
    private func loadCategories() -> [IconCategory] {
        guard let iconFolderURL = IconPng.iconFolderURL else {
            print("未找到图标文件夹")
            return []
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: iconFolderURL.path)
            let categories = items.compactMap { item -> IconCategory? in
                let itemPath = (iconFolderURL.path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                return IconCategory.fromFolder(itemPath)
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            print("无法获取分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> IconCategory? {
        categories.first { $0.name == name }
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
