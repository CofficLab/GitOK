import AVKit
import MagicKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

/// 图标提供者，统一管理所有图标插件相关的状态
class IconProvider: NSObject, ObservableObject, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🍒"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @Published private(set) var currentData: IconData? = nil

    /// 当前从候选列表中选中的图标ID
    /// 用于在图标选择器中高亮显示选中的图标
    @Published var selectedIconId: String = ""

    /// 当前选中的分类
    @Published var selectedCategory: IconCategory?

    /// 当前选中的图标来源标识（用于无分类来源的增删操作）
    @Published var selectedSourceIdentifier: String? = nil

    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        return selectedCategory?.name ?? ""
    }

    /// 初始化图标提供者
    override init() {
        super.init()

        if Self.verbose {
            os_log("\(self.t)Initializing IconProvider")
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

    /// 处理图标保存通知
    /// - Parameter notification: 通知对象
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

    /// 处理图标删除通知
    /// - Parameter notification: 通知对象
    @objc private func handleIconDidDelete(_ notification: Notification) {
        let path = notification.userInfo?["path"] as? String
        if let path = path, path == self.currentData?.path {
            self.currentData = nil
        }
    }

    /// 更新当前模型
    /// - Parameter newModel: 新的图标数据模型
    func updateCurrentModel(newModel: IconData?) {
        self.currentData = newModel
        self.selectedIconId = newModel?.iconId ?? ""
    }

    /// 选择图标
    /// - Parameter iconId: 图标ID
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

    /// 选择图标分类
    /// - Parameter category: 图标分类
    func selectCategory(_ category: IconCategory?) {
        self.selectedCategory = category
    }

    /// 清空选中的分类
    func clearSelectedCategory() {
        self.selectedCategory = nil
    }

    /// 向项目图标库添加图片
    /// - Parameters:
    ///   - data: 图像二进制数据
    ///   - filename: 文件名（包含扩展名）
    /// - Returns: 是否成功
    func addImageToProjectLibrary(data: Data, filename: String) -> Bool {
        guard let sid = selectedCategory?.sourceIdentifier ?? selectedSourceIdentifier else { return false }
        let ok = awaitResult { await IconRepo.shared.addImage(data: data, filename: filename, to: sid) }
        return ok
    }

    /// 从项目图标库删除图片
    /// - Parameter filename: 文件名（包含扩展名）
    /// - Returns: 是否成功
    func deleteImageFromProjectLibrary(filename: String) -> Bool {
        guard let sid = selectedCategory?.sourceIdentifier ?? selectedSourceIdentifier else { return false }
        let ok = awaitResult { await IconRepo.shared.deleteImage(filename: filename, from: sid) }
        if ok {
            if selectedIconId.hasSuffix("/\(filename)") || selectedIconId == filename {
                selectedIconId = ""
            }
        }
        return ok
    }

    /// 等待异步操作结果
    /// - Parameter op: 异步操作
    /// - Returns: 操作结果
    private func awaitResult(_ op: @escaping () async -> Bool) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await op()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideTabPicker()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
