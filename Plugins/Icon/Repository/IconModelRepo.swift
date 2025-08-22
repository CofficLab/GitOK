import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 图标模型仓库
 * 负责根据根目录扫描和获取所有的IconModel
 * 支持动态扫描、缓存管理和批量操作
 */
class IconModelRepo: ObservableObject, SuperLog {
    nonisolated static var emoji: String { "📱" }
    
    /// 单例实例
    static let shared = IconModelRepo()
    
    /// 根目录URL
    private var rootURL: URL?
    
    /// 所有扫描到的图标模型
    @Published private(set) var iconModels: [IconModel] = []
    
    /// 是否正在扫描
    @Published private(set) var isScanning = false
    
    /// 扫描错误信息
    @Published private(set) var scanError: String?
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 设置根目录并扫描图标模型
    /// - Parameter rootURL: 要扫描的根目录URL
    func scanIconModels(from rootURL: URL) {
        self.rootURL = rootURL
        self.isScanning = true
        self.scanError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let models = self?.scanDirectory(rootURL) ?? []
            
            DispatchQueue.main.async {
                self?.iconModels = models
                self?.isScanning = false
                os_log("\(self?.t ?? "")✅ 扫描完成，找到 \(models.count) 个图标模型")
            }
        }
    }
    
    /// 扫描目录获取图标模型
    /// - Parameter directoryURL: 要扫描的目录URL
    /// - Returns: 图标模型数组
    private func scanDirectory(_ directoryURL: URL) -> [IconModel] {
        var models: [IconModel] = []
        
        do {
            let enumerator = FileManager.default.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            while let fileURL = enumerator?.nextObject() as? URL {
                // 检查是否是图标配置文件
                if fileURL.pathExtension == "json" {
                    if let model = tryLoadIconModel(from: fileURL) {
                        models.append(model)
                    }
                }
            }
        } catch {
            os_log(.error, "\(self.t)扫描目录失败：\(error.localizedDescription)")
            DispatchQueue.main.async {
                self.scanError = "扫描目录失败：\(error.localizedDescription)"
            }
        }
        
        // 按标题排序，保持稳定的顺序
        return models.sorted { (model1: IconModel, model2: IconModel) in
            return model1.title < model2.title
        }
    }
    
    /// 尝试加载图标模型
    /// - Parameter fileURL: 图标配置文件URL
    /// - Returns: 图标模型，如果加载失败则返回nil
    private func tryLoadIconModel(from fileURL: URL) -> IconModel? {
        do {
            let model = try IconModel.fromJSONFile(fileURL)
            return model
        } catch {
            // 不是有效的图标配置文件，忽略
            return nil
        }
    }
    
    /// 刷新图标模型列表
    func refreshIconModels() {
        guard let rootURL = rootURL else {
            os_log(.error, "\(self.t)未设置根目录，无法刷新")
            return
        }
        scanIconModels(from: rootURL)
    }
    
    /// 根据路径查找图标模型
    /// - Parameter path: 图标模型文件路径
    /// - Returns: 图标模型，如果不存在则返回nil
    func findIconModel(byPath path: String) -> IconModel? {
        iconModels.first { $0.path == path }
    }
    
    /// 根据ID查找图标模型
    /// - Parameter id: 图标模型ID
    /// - Returns: 图标模型，如果不存在则返回nil
    func findIconModel(byId id: String) -> IconModel? {
        iconModels.first { $0.id == id }
    }
    
    /// 根据标题查找图标模型
    /// - Parameter title: 图标模型标题
    /// - Returns: 图标模型数组
    func findIconModels(byTitle title: String) -> [IconModel] {
        iconModels.filter { $0.title.localizedCaseInsensitiveContains(title) }
    }
    
    /// 获取所有图标模型
    /// - Returns: 图标模型数组
    func getAllIconModels() -> [IconModel] {
        iconModels
    }
    
    /// 获取图标模型总数
    var totalCount: Int {
        iconModels.count
    }
    
    /// 获取最近修改的图标模型
    /// - Parameter count: 返回的数量
    /// - Returns: 最近修改的图标模型数组
    func getRecentIconModels(count: Int = 10) -> [IconModel] {
        Array(iconModels.prefix(count))
    }
    
    /// 获取指定时间范围内修改的图标模型
    /// - Parameters:
    ///   - since: 开始时间
    ///   - until: 结束时间
    /// - Returns: 符合条件的图标模型数组
    /// 获取指定标题范围的图标模型
    /// - Parameters:
    ///   - startTitle: 开始标题
    ///   - endTitle: 结束标题
    /// - Returns: 符合条件的图标模型数组
    func getIconModelsInTitleRange(from startTitle: String, to endTitle: String) -> [IconModel] {
        iconModels.filter { (model: IconModel) in
            return model.title >= startTitle && model.title <= endTitle
        }
    }
    
    /// 获取图标模型统计信息
    /// - Returns: 统计信息字典
    func getStatistics() -> [String: Any] {
        let totalIconIds = iconModels.reduce(into: 0) { result, model in
            result += model.iconId
        }
        let avgIconId = totalCount > 0 ? totalIconIds / totalCount : 0
        
        return [
            "totalCount": totalCount,
            "totalIconIds": totalIconIds,
            "averageIconId": avgIconId,
            "lastScanTime": Date(),
            "rootDirectory": rootURL?.path ?? "未设置"
        ]
    }
    
    /// 清除所有图标模型
    func clearIconModels() {
        iconModels.removeAll()
        rootURL = nil
        scanError = nil
    }
    
    /// 检查是否已设置根目录
    var hasRootDirectory: Bool {
        rootURL != nil
    }
    
    /// 获取当前根目录
    var currentRootDirectory: URL? {
        rootURL
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
