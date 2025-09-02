import Foundation
import MagicCore
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
    
    /// Banner标题
    var title: String = "Banner Title"
    
    /// Banner副标题
    var subTitle: String = "Banner SubTitle"
    
    /// 功能特性列表
    var features: [String] = []
    
    /// 图片资源ID（可选）
    var imageId: String?
    
    /// 背景样式ID
    var backgroundId: String = "1"
    
    /// 是否在屏幕中显示
    var inScreen: Bool = false
    
    /// 透明度（0.0 - 1.0）
    var opacity: Double = 1.0
    
    /// 配置文件路径
    var path: String
    
    /// 所属项目
    var project: Project
    
    /// 标题颜色（可选）
    var titleColor: Color?
    
    /// 副标题颜色（可选）
    var subTitleColor: Color?
    
    /// 模板特定的数据（JSON格式存储）
    var templateData: String?
    
    // MARK: - 初始化方法
    
    init(
        title: String = "Banner Title",
        subTitle: String = "Banner SubTitle",
        features: [String] = [],
        imageId: String? = nil,
        backgroundId: String = "1",
        inScreen: Bool = false,
        opacity: Double = 1.0,
        path: String,
        project: Project,
        titleColor: Color? = nil,
        subTitleColor: Color? = nil,
        templateData: String? = nil
    ) {
        self.title = title
        self.subTitle = subTitle
        self.features = features
        self.imageId = imageId
        self.backgroundId = backgroundId
        self.inScreen = inScreen
        self.opacity = opacity
        self.path = path
        self.project = project
        self.titleColor = titleColor
        self.subTitleColor = subTitleColor
        self.templateData = templateData
    }
    
    // MARK: - 业务方法
    
    /// 获取图片
    /// - Returns: SwiftUI Image对象
    func getImage() -> Image {
        var image = Image("Snapshot-1")
        
        if let generatedIcon = getGeneratedIcon() {
            image = generatedIcon.getImage(self.project.url)
        }
        
        return image
    }
    
    /// 获取生成的图标
    /// - Returns: GeneratedIcon对象（如果存在）
    func getGeneratedIcon() -> ProjectImage? {
        guard let imageId = self.imageId else {
            return nil
        }
        
        return ProjectImage.fromImageId(imageId)
    }
    
    /// 更改图片
    /// - Parameter url: 新图片的URL
    mutating func changeImage(_ url: URL) throws {
        // 保存图片并获取新的imageId
        let newImageId = try saveImage(url)
        self.imageId = newImageId
        
        os_log(.info, "\(Self.emoji) 更改图片成功: \(newImageId)")
    }
    
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

// MARK: - Update

extension BannerFile { 
    mutating func updateBackgroundId(_ backgroundId: String) throws {
        self.backgroundId = backgroundId
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
        case title
        case subTitle
        case features
        case imageId
        case backgroundId
        case inScreen
        case opacity
        case titleColor
        case subTitleColor
        case templateData
        // path 和 project 不需要序列化，它们在加载时设置
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Banner Title"
        subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle) ?? "Banner SubTitle"
        features = try container.decodeIfPresent([String].self, forKey: .features) ?? []
        imageId = try container.decodeIfPresent(String.self, forKey: .imageId)
        backgroundId = try container.decodeIfPresent(String.self, forKey: .backgroundId) ?? "1"
        inScreen = try container.decodeIfPresent(Bool.self, forKey: .inScreen) ?? false
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        
        // 这些值在反序列化时临时设置，实际值由ProjectBannerRepo在加载时设置
        path = ""
        project = Project.null
        titleColor = nil
        subTitleColor = nil
        templateData = try container.decodeIfPresent(String.self, forKey: .templateData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(subTitle, forKey: .subTitle)
        try container.encode(features, forKey: .features)
        try container.encodeIfPresent(imageId, forKey: .imageId)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encode(inScreen, forKey: .inScreen)
        try container.encode(opacity, forKey: .opacity)
        try container.encodeIfPresent(templateData, forKey: .templateData)
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
