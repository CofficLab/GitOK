import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
    Banner仓库管理器
    统一管理Banner相关的数据操作，提供清晰的数据访问接口
    类似于IconRepo的架构模式，支持多种Banner数据来源
**/
class BannerRepo: SuperLog {
    nonisolated static var emoji: String { "📣" }

    /// 单例实例
    static let shared = BannerRepo()

    /// 私有初始化方法，确保单例模式
    private init() {
    }
    
    // MARK: - 项目Banner管理
    
    /// Banner存储目录路径（相对于项目根目录）
    static let bannerStoragePath = ".gitok/banners"
    
    /// 获取项目下的所有Banner
    /// - Parameter project: Project对象
    /// - Returns: 该项目下的所有BannerData数组
    func getBanners(from project: Project) -> [BannerFile] {
        return getBannerData(from: project)
    }

    /// 根据ID查找Banner
    /// - Parameters:
    ///   - id: Banner的ID
    ///   - project: 所属项目
    /// - Returns: 找到的BannerFile，如果未找到则返回nil
    func getBanner(by id: String, from project: Project) -> BannerFile? {
        let banners = getBanners(from: project)
        return banners.first { $0.id == id }
    }
    
    /// 从Project对象获取所有Banner模型
    /// - Parameter project: Project对象
    /// - Returns: 该project下的所有BannerData数组
    private func getBannerData(from project: Project) -> [BannerFile] {
        let projectRootURL = URL(fileURLWithPath: project.path)
        let bannerDirectoryURL = projectRootURL.appendingPathComponent(Self.bannerStoragePath)
        
        var models: [BannerFile] = []
        
        do {
            // 检查Banner目录是否存在
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: bannerDirectoryURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return []
            }
            
            // 扫描Banner目录中的所有JSON文件
            let files = try FileManager.default.contentsOfDirectory(atPath: bannerDirectoryURL.path)
            for file in files {
                if file.hasSuffix(".json") {
                    let fileURL = bannerDirectoryURL.appendingPathComponent(file)
                    if let model = tryLoadBannerData(from: fileURL, project: project) {
                        models.append(model)
                    }
                }
            }
        } catch {
            os_log(.error, "\(Self.emoji) 扫描Banner目录失败: \(error.localizedDescription)")
            return []
        }
        
        // 按标题排序，保持稳定的顺序
        return models.sorted { $0.title < $1.title }
    }
    
    /// 尝试加载Banner模型
    /// - Parameters:
    ///   - fileURL: Banner配置文件URL
    ///   - project: 所属项目
    /// - Returns: Banner模型，如果加载失败则返回nil
    private func tryLoadBannerData(from fileURL: URL, project: Project) -> BannerFile? {
        do {
            let data = try Data(contentsOf: fileURL)
            var bannerData = try JSONDecoder().decode(BannerFile.self, from: data)
            bannerData.path = fileURL.path
            bannerData.project = project
            return bannerData
        } catch {
            os_log(.error, "\(Self.emoji) 加载Banner失败 \(fileURL.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建新的Banner
    /// - Parameters:
    ///   - project: 所属项目
    ///   - title: Banner标题
    /// - Returns: 新创建的BannerData
    func createBanner(in project: Project, title: String = "New Banner") throws -> BannerFile {
        let projectRootURL = URL(fileURLWithPath: project.path)
        let bannerDirectoryURL = projectRootURL.appendingPathComponent(Self.bannerStoragePath)
        
        // 确保Banner目录存在
        try FileManager.default.createDirectory(at: bannerDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        // 生成唯一的文件名
        let timestamp = Date().timeIntervalSince1970
        let fileName = "banner_\(Int(timestamp)).json"
        let fileURL = bannerDirectoryURL.appendingPathComponent(fileName)
        
        // 创建新的BannerData
        var bannerData = BannerFile(
            title: title,
            path: fileURL.path,
            project: project
        )
        
        // 保存到文件
        try saveBannerToFile(bannerData, at: fileURL)
        
        // 发送创建通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .bannerAdded, 
                object: bannerData, 
                userInfo: ["id": bannerData.id]
            )
        }
        
        os_log(.info, "\(Self.emoji) 创建新Banner: \(title)")
        return bannerData
    }
    
    /// 保存Banner数据
    /// - Parameter banner: 要保存的Banner数据
    func saveBanner(_ banner: BannerFile) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        try saveBannerToFile(banner, at: fileURL)
        
        // 发送保存通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidSave, object: banner)
        }
        
        os_log(.info, "\(Self.emoji) 保存Banner: \(banner.title)")
    }
    
    /// 将Banner数据保存到文件
    /// - Parameters:
    ///   - banner: Banner数据
    ///   - fileURL: 文件URL
    private func saveBannerToFile(_ banner: BannerFile, at fileURL: URL) throws {
        let data = try JSONEncoder().encode(banner)
        try data.write(to: fileURL)
    }
    
    /// 删除Banner
    /// - Parameter banner: 要删除的Banner数据
    func deleteBanner(_ banner: BannerFile) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        
        // 删除文件
        try FileManager.default.removeItem(at: fileURL)
        
        // 发送删除通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidDelete, object: banner, userInfo: ["id": banner.id])
        }
        
        os_log(.info, "\(Self.emoji) 删除Banner: \(banner.title)")
    }
    
    /// 更新Banner数据
    /// - Parameters:
    ///   - banner: 原Banner数据
    ///   - updates: 更新的数据
    /// - Returns: 更新后的BannerData
    func updateBanner(_ banner: BannerFile, with updates: BannerDataUpdate) throws -> BannerFile {
        var updatedBanner = banner
        
        // 应用更新
        if let title = updates.title { updatedBanner.title = title }
        if let subTitle = updates.subTitle { updatedBanner.subTitle = subTitle }
        if let features = updates.features { updatedBanner.features = features }
        if let imageId = updates.imageId { updatedBanner.imageId = imageId }
        if let backgroundId = updates.backgroundId { updatedBanner.backgroundId = backgroundId }
        if let opacity = updates.opacity { updatedBanner.opacity = opacity }
        
        // 保存更新后的数据
        try saveBanner(updatedBanner)
        
        return updatedBanner
    }
}

/// Banner数据更新结构
struct BannerDataUpdate {
    var title: String?
    var subTitle: String?
    var features: [String]?
    var imageId: String?
    var backgroundId: String?
    var device: String?
    var opacity: Double?
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
