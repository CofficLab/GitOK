import Foundation
import MagicKit
import OSLog
import SwiftUI

/**
    Banner数据模型
    纯数据存储结构，负责存储Banner的配置信息
    不包含任何UI渲染逻辑，只负责数据的序列化和反序列化
    类似于IconData的设计模式，遵循单一职责原则
**/
struct BannerFile: SuperLog {
    static var emoji = "📄"
    static var empty = BannerFile(path: "", project: Project.null)
    
    // MARK: - 基本属性
    
    /// 配置文件路径
    var path: String
    
    /// 所属项目
    var project: Project
    
    /// 模板特定的数据（JSON格式存储）
    /// key 是模板的 ID，value 是模板的数据
    var templateData: [String: String] = [:]
    
    /// 最后选择的模板ID
    var lastSelectedTemplateId: String = ""
    
    // MARK: - 初始化方法
    
    init(
        path: String,
        project: Project,
        templateData: [String: String] = [:],
        lastSelectedTemplateId: String = ""
    ) {
        self.path = path
        self.project = project
        self.templateData = templateData
        self.lastSelectedTemplateId = lastSelectedTemplateId
    }
    
    // MARK: - 业务方法
    
    /// 保存到磁盘
    /// - Throws: 保存失败时抛出错误
    func saveToDisk() throws {
        try BannerRepo.shared.saveBanner(self)
    }
    
    /// 保存图片到项目目录
    /// - Parameter url: 图片URL
    /// - Returns: 保存后的图片相对路径
    func saveImage(_ url: URL) throws -> String {
        let ext = url.pathExtension
        let projectURL = URL(fileURLWithPath: project.path)
        let bannerRootURL = projectURL.appendingPathComponent(BannerRepo.bannerStoragePath)
        let imagesFolder = bannerRootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")
        
        os_log(.info, "\(Self.emoji) 保存图片")
        os_log(.info, "  ➡️ 源: \(url.relativeString)")
        os_log(.info, "  ➡️ 目标: \(storeURL.relativeString)")
        
        do {
            // 确保图片目录存在
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)
            
            // 复制图片到新位置
            try FileManager.default.copyItem(at: url, to: storeURL)
            return storeURL.relativePath.replacingOccurrences(of: self.project.path, with: "")
        } catch {
            os_log(.error, "\(Self.emoji) 保存图片失败: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Template Data

extension BannerFile {
    /// 获取模板数据
    /// - Parameter templateId: 模板ID
    /// - Returns: 模板数据的JSON字符串
    func getTemplateData(_ templateId: String) -> String? {
        return templateData[templateId]
    }
    
    /// 设置模板数据
    /// - Parameters:
    ///   - templateId: 模板ID
    ///   - data: 模板数据的JSON字符串
    mutating func setTemplateData(_ templateId: String, data: String) throws {
        templateData[templateId] = data
        try self.saveToDisk()
    }
}

// MARK: - Identifiable

extension BannerFile: Identifiable {
    var id: String {
        path
    }
}

// MARK: - Equatable

extension BannerFile: Equatable {
    static func == (lhs: BannerFile, rhs: BannerFile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension BannerFile: Codable {
    enum CodingKeys: String, CodingKey {
        case templateData
        case lastSelectedTemplateId
        // path 和 project 不需要序列化，它们在加载时设置
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 这些值在反序列化时临时设置，实际值由ProjectBannerRepo在加载时设置
        path = ""
        project = Project.null
        templateData = try container.decodeIfPresent([String: String].self, forKey: .templateData) ?? [:]
        lastSelectedTemplateId = try container.decodeIfPresent(String.self, forKey: .lastSelectedTemplateId) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateData, forKey: .templateData)
        try container.encode(lastSelectedTemplateId, forKey: .lastSelectedTemplateId)
    }
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
