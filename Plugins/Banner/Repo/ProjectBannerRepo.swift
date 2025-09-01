import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
    项目Banner仓库
    负责从项目目录扫描和获取所有的BannerData
    处理Banner文件的创建、读取、更新、删除操作
**/
class ProjectBannerRepo: SuperLog {
    nonisolated static var emoji: String { "🏗️" }
    
    /// Banner存储目录路径（相对于项目根目录）
    static let bannerStoragePath = ".gitok/banners"
    
    // MARK: - 读取操作
    
    /// 从Project对象获取所有Banner模型
    /// - Parameter project: Project对象
    /// - Returns: 该project下的所有BannerData数组
    static func getBannerData(from project: Project) -> [BannerData] {
        let projectRootURL = URL(fileURLWithPath: project.path)
        let bannerDirectoryURL = projectRootURL.appendingPathComponent(bannerStoragePath)
        
        var models: [BannerData] = []
        
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
    private static func tryLoadBannerData(from fileURL: URL, project: Project) -> BannerData? {
        do {
            let data = try Data(contentsOf: fileURL)
            var bannerData = try JSONDecoder().decode(BannerData.self, from: data)
            bannerData.path = fileURL.path
            bannerData.project = project
            return bannerData
        } catch {
            os_log(.error, "\(Self.emoji) 加载Banner失败 \(fileURL.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 创建操作
    
    /// 创建新的Banner
    /// - Parameters:
    ///   - project: 所属项目
    ///   - title: Banner标题
    /// - Returns: 新创建的BannerData
    static func createBanner(in project: Project, title: String = "New Banner") throws -> BannerData {
        let projectRootURL = URL(fileURLWithPath: project.path)
        let bannerDirectoryURL = projectRootURL.appendingPathComponent(bannerStoragePath)
        
        // 确保Banner目录存在
        try FileManager.default.createDirectory(at: bannerDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        // 生成唯一的文件名
        let timestamp = Date().timeIntervalSince1970
        let fileName = "banner_\(Int(timestamp)).json"
        let fileURL = bannerDirectoryURL.appendingPathComponent(fileName)
        
        // 创建新的BannerData
        var bannerData = BannerData(
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
    
    // MARK: - 保存操作
    
    /// 保存Banner数据
    /// - Parameter banner: 要保存的Banner数据
    static func saveBanner(_ banner: BannerData) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        try saveBannerToFile(banner, at: fileURL)
        
        // 发送保存通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidSave, object: banner, userInfo: ["id": banner.id])
        }
        
        os_log(.info, "\(Self.emoji) 保存Banner: \(banner.title)")
    }
    
    /// 将Banner数据保存到文件
    /// - Parameters:
    ///   - banner: Banner数据
    ///   - fileURL: 文件URL
    private static func saveBannerToFile(_ banner: BannerData, at fileURL: URL) throws {
        let data = try JSONEncoder().encode(banner)
        try data.write(to: fileURL)
    }
    
    // MARK: - 更新操作
    
    /// 更新Banner数据
    /// - Parameters:
    ///   - banner: 原Banner数据
    ///   - updates: 更新的数据
    /// - Returns: 更新后的BannerData
    static func updateBanner(_ banner: BannerData, with updates: BannerDataUpdate) throws -> BannerData {
        var updatedBanner = banner
        
        // 应用更新
        if let title = updates.title { updatedBanner.title = title }
        if let subTitle = updates.subTitle { updatedBanner.subTitle = subTitle }
        if let features = updates.features { updatedBanner.features = features }
        if let imageId = updates.imageId { updatedBanner.imageId = imageId }
        if let backgroundId = updates.backgroundId { updatedBanner.backgroundId = backgroundId }
        if let device = updates.device { updatedBanner.device = device }
        if let opacity = updates.opacity { updatedBanner.opacity = opacity }
        
        // 保存更新后的数据
        try saveBanner(updatedBanner)
        
        return updatedBanner
    }
    
    // MARK: - 删除操作
    
    /// 删除Banner
    /// - Parameter banner: 要删除的Banner数据
    static func deleteBanner(_ banner: BannerData) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        
        // 删除文件
        try FileManager.default.removeItem(at: fileURL)
        
        // 发送删除通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidDelete, object: banner, userInfo: ["id": banner.id])
        }
        
        os_log(.info, "\(Self.emoji) 删除Banner: \(banner.title)")
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
