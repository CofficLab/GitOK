import SwiftUI
import GitOKCoreKit
import GitOKSupportKit

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
