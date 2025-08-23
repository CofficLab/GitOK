import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 项目图标仓库
 * 负责从项目目录扫描和获取所有的IconModel
 * 管理IconModel的存储目录，支持动态扫描和缓存管理
 */
class ProjectIconRepo: ObservableObject, SuperLog {
    nonisolated static var emoji: String { "📱" }
    
    /// 单例实例
    static let shared = ProjectIconRepo()
    
    /// 项目根目录URL
    private var projectRootURL: URL?
    
    /// 图标存储目录路径（相对于项目根目录）
    private let iconStoragePath = IconModel.root
    
    /// 所有扫描到的图标模型
    @Published private(set) var iconModels: [IconModel] = []
    
    /// 是否正在扫描
    @Published private(set) var isScanning = false
    
    /// 扫描错误信息
    @Published private(set) var scanError: String?
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 设置项目根目录并扫描图标模型
    /// - Parameter projectRootURL: 项目根目录URL
    func scanIconModels(fromProject projectRootURL: URL) {
        self.projectRootURL = projectRootURL
        self.isScanning = true
        self.scanError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let models = self?.scanProjectDirectory(projectRootURL) ?? []
            
            DispatchQueue.main.async {
                self?.iconModels = models
                self?.isScanning = false
                os_log("\(self?.t ?? "")✅ 扫描完成，找到 \(models.count) 个图标模型")
            }
        }
    }
    
    /// 扫描项目目录获取图标模型
    /// - Parameter projectRootURL: 项目根目录URL
    /// - Returns: 图标模型数组
    private func scanProjectDirectory(_ projectRootURL: URL) -> [IconModel] {
        var models: [IconModel] = []
        
        // 构建图标存储目录的完整路径
        let iconDirectoryURL = projectRootURL.appendingPathComponent(iconStoragePath)
        
        do {
            // 检查图标目录是否存在
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: iconDirectoryURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                os_log("\(self.t)图标目录不存在：\(iconDirectoryURL.path)")
                return []
            }
            
            // 扫描图标目录中的所有JSON文件
            let files = try FileManager.default.contentsOfDirectory(atPath: iconDirectoryURL.path)
            for file in files {
                if file.hasSuffix(".json") {
                    let fileURL = iconDirectoryURL.appendingPathComponent(file)
                    if let model = tryLoadIconModel(from: fileURL) {
                        models.append(model)
                    }
                }
            }
        } catch {
            os_log(.error, "\(self.t)扫描项目目录失败：\(error.localizedDescription)")
            DispatchQueue.main.async {
                self.scanError = "扫描项目目录失败：\(error.localizedDescription)"
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
        guard let projectRootURL = projectRootURL else {
            os_log(.error, "\(self.t)未设置项目根目录，无法刷新")
            return
        }
        scanIconModels(fromProject: projectRootURL)
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
    
    /// 清除所有图标模型
    func clearIconModels() {
        iconModels.removeAll()
        projectRootURL = nil
        scanError = nil
    }
    
    /// 检查是否已设置项目根目录
    var hasProjectRootDirectory: Bool {
        projectRootURL != nil
    }
    
    /// 获取当前项目根目录
    var currentProjectRootDirectory: URL? {
        projectRootURL
    }
    
    /// 获取图标存储目录的完整路径
    var iconStorageDirectory: URL? {
        guard let projectRootURL = projectRootURL else { return nil }
        return projectRootURL.appendingPathComponent(iconStoragePath)
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
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
