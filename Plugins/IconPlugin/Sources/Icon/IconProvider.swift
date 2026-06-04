import AVKit
import MagicLog
import GitOKCoreKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

/// 图标提供者，统一管理所有图标插件相关的状态
@MainActor
public class IconProvider: NSObject, ObservableObject, SuperLog {
    /// emoji 标识符
    public nonisolated static let emoji = "🍒"

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

    private var pendingSaveTask: Task<Void, Never>?

    /// 当前选中的图标分类名称（兼容性属性）
    var selectedCategoryName: String {
        return selectedCategory?.name ?? ""
    }

    /// 初始化图标提供者
    public override init() {
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
        pendingSaveTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    /// 处理图标保存通知
    /// - Parameter notification: 通知对象
    @objc private func handleIconDidSave(_ notification: Notification) {
        // 只有在图标真正保存时才更新模型，避免参数调整时的频繁更新
        guard let iconPath = self.currentData?.path else { return }

        Task {
            let newModel = await Task.detached(priority: .utility) {
                try? IconData.fromJSONFile(URL(fileURLWithPath: iconPath))
            }.value

            guard self.currentData?.path == iconPath,
                  let newModel,
                  newModel != self.currentData else {
                return
            }

            self.updateCurrentModel(newModel: newModel)
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
            model.iconId = iconId
            self.currentData = model

            scheduleSave(model, operation: "update model iconId")
        }
    }

    func updateImageURL(_ url: URL) {
        guard var model = self.currentData else {
            os_log(.error, "\(self.t)Failed to update image URL: missing current model")
            return
        }

        model.imageURL = url
        self.currentData = model

        scheduleSave(model, operation: "update image URL")
    }

    func updateOpacity(_ opacity: Double) {
        updateCurrentModelAndSave { model in
            model.opacity = opacity
        }
    }

    func updateScale(_ scale: Double) {
        updateCurrentModelAndSave { model in
            model.scale = scale
        }
    }

    func updateCornerRadius(_ radius: Double) {
        updateCurrentModelAndSave { model in
            model.cornerRadius = max(0, min(radius, 512))
        }
    }

    func updatePadding(_ padding: Double) {
        updateCurrentModelAndSave { model in
            model.padding = padding
        }
    }

    func updateBackgroundId(_ id: String) {
        updateCurrentModelAndSave { model in
            model.backgroundId = id
        }
    }

    private func updateCurrentModelAndSave(_ update: (inout IconData) -> Void) {
        guard var model = self.currentData else {
            os_log(.error, "\(self.t)Failed to update icon model: missing current model")
            return
        }

        update(&model)
        self.currentData = model

        scheduleSave(model, operation: "save icon model")
    }

    private func scheduleSave(_ model: IconData, operation: String) {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { [weak self, model, operation] in
            do {
                try await Task.sleep(nanoseconds: 150_000_000)
                try Task.checkCancellation()
                try await model.saveToDiskAsync()
            } catch is CancellationError {
            } catch {
                guard let self else { return }
                os_log(.error, "\(self.t)Failed to \(operation): \(error)")
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
    func addImageToProjectLibrary(data: Data, filename: String) async -> Bool {
        guard let sid = selectedCategory?.sourceIdentifier ?? selectedSourceIdentifier else { return false }
        return await IconRepo.shared.addImage(data: data, filename: filename, to: sid)
    }

    /// 从项目图标库删除图片
    /// - Parameter filename: 文件名（包含扩展名）
    /// - Returns: 是否成功
    func deleteImageFromProjectLibrary(filename: String) async -> Bool {
        guard let sid = selectedCategory?.sourceIdentifier ?? selectedSourceIdentifier else { return false }
        let ok = await IconRepo.shared.deleteImage(filename: filename, from: sid)
        if ok {
            if selectedIconId.hasSuffix("/\(filename)") || selectedIconId == filename {
                selectedIconId = ""
            }
        }
        return ok
    }
}

// MARK: - Preview
