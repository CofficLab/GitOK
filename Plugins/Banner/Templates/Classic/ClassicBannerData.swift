import SwiftUI
import MagicCore
import MagicAll
import MagicUI

/**
 经典布局的数据模型
 */
struct ClassicBannerData: Codable {
    var title: String = "Banner Title"
    var subTitle: String = "Banner SubTitle"
    var features: [String] = []
    var imageId: String? = nil
    var backgroundId: String = "1"
    var selectedDevice: MagicDevice? = nil
    var opacity: Double = 1.0
    var titleColor: Color? = nil
    var subTitleColor: Color? = nil
    
    static let defaultImageId = "Snapshot-iPhone"
    static let templateId = "classic"
    
    init(
        title: String = "Banner Title",
        subTitle: String = "Banner SubTitle",
        features: [String] = [],
        imageId: String? = nil,
        backgroundId: String = "1",
        selectedDevice: MagicDevice? = nil,
        opacity: Double = 1.0,
        titleColor: Color? = nil,
        subTitleColor: Color? = nil
    ) {
        self.title = title
        self.subTitle = subTitle
        self.features = features
        self.imageId = imageId
        self.backgroundId = backgroundId
        self.selectedDevice = selectedDevice
        self.opacity = opacity
        self.titleColor = titleColor
        self.subTitleColor = subTitleColor
    }
    
    enum CodingKeys: String, CodingKey {
        case title, subTitle, features, imageId, backgroundId, selectedDevice, opacity
        // 颜色暂时不需要序列化，因为 SwiftUI.Color 不支持 Codable
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Banner Title"
        subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle) ?? "Banner SubTitle"
        features = try container.decodeIfPresent([String].self, forKey: .features) ?? []
        imageId = try container.decodeIfPresent(String.self, forKey: .imageId)
        backgroundId = try container.decodeIfPresent(String.self, forKey: .backgroundId) ?? "1"
        if let deviceRawValue = try container.decodeIfPresent(String.self, forKey: .selectedDevice) {
            selectedDevice = MagicDevice(rawValue: deviceRawValue)
        }
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(subTitle, forKey: .subTitle)
        try container.encode(features, forKey: .features)
        try container.encodeIfPresent(imageId, forKey: .imageId)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encodeIfPresent(selectedDevice?.rawValue, forKey: .selectedDevice)
        try container.encode(opacity, forKey: .opacity)
    }
    
    // MARK: - 图片处理
    
    /// 获取图片
    /// - Parameter projectURL: 项目URL
    /// - Returns: SwiftUI Image对象
    func getImage(_ projectURL: URL) -> Image {
        guard let imageId = self.imageId else {
            return Image(Self.defaultImageId)
        }
        
        // 移除路径中的多余转义字符
        let cleanPath = imageId.replacingOccurrences(of: "\\/", with: "/")
        let imageURL = URL(fileURLWithPath: projectURL.path).appendingPathComponent(cleanPath)
        
        if let nsImage = NSImage(contentsOf: imageURL) {
            return Image(nsImage: nsImage)
        }
        
        return Image(Self.defaultImageId)
    }
    
    /// 更改图片
    /// - Parameters:
    ///   - url: 新图片的URL
    ///   - projectURL: 项目URL
    /// - Returns: 更新后的数据
    mutating func changeImage(_ url: URL, projectURL: URL) throws -> Self {
        // 保存图片并获取新的imageId
        let newImageId = try saveImage(url, projectURL: projectURL)
        self.imageId = newImageId
        
        return self
    }
    
    /// 保存图片到项目目录
    /// - Parameters:
    ///   - url: 图片URL
    ///   - projectURL: 项目URL
    /// - Returns: 保存后的图片相对路径
    private func saveImage(_ url: URL, projectURL: URL) throws -> String {
        let ext = url.pathExtension
        let bannerRootURL = projectURL.appendingPathComponent(BannerRepo.bannerStoragePath)
        let imagesFolder = bannerRootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")
        
        do {
            // 确保图片目录存在
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)
            
            // 复制图片到新位置
            try FileManager.default.copyItem(at: url, to: storeURL)
            return storeURL.relativePath.replacingOccurrences(of: projectURL.path, with: "")
        } catch {
            throw error
        }
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
