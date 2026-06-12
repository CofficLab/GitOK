import SwiftUI
import GitOKCoreKit
import GitOKSupportKit

/**
 简约布局的数据模型
 */
struct MinimalBannerData: Codable {
    var title: String = "App Title"
    var imageId: String? = nil
    var backgroundId: String = "1"
    var selectedDevice: MagicDevice? = nil
    var opacity: Double = 1.0
    var titleColor: Color? = nil

    static let templateId = "minimal"

    init(
        title: String = "App Title",
        imageId: String? = nil,
        backgroundId: String = "1",
        selectedDevice: MagicDevice? = nil,
        opacity: Double = 1.0,
        titleColor: Color? = nil
    ) {
        self.title = title
        self.imageId = imageId
        self.backgroundId = backgroundId
        self.selectedDevice = selectedDevice
        self.opacity = opacity
        self.titleColor = titleColor
    }

    enum CodingKeys: String, CodingKey {
        case title, imageId, backgroundId, selectedDevice, opacity
        // 颜色暂时不需要序列化，因为 SwiftUI.Color 不支持 Codable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "App Title"
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
        try container.encodeIfPresent(imageId, forKey: .imageId)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encodeIfPresent(selectedDevice?.rawValue, forKey: .selectedDevice)
        try container.encode(opacity, forKey: .opacity)
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
    /// - Parameters:
    ///   - url: 新图片的URL
    ///   - projectURL: 项目URL
    /// - Returns: 更新后的数据
    mutating func changeImageAsync(_ url: URL, projectURL: URL) async throws -> Self {
        // 保存图片并获取新的imageId
        let newImageId = try await BannerImageFileOperations.saveImportedImage(url, projectURL: projectURL)
        self.imageId = newImageId

        return self
    }
}
