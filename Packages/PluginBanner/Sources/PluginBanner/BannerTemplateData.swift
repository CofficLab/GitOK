import BannerCoreKit
import Foundation

public enum BannerTemplateID {
    public static let classic = "classic"
    public static let minimal = "minimal"
    public static let all = [classic, minimal]
}

/// Persisted data for the classic banner template.
public struct ClassicBannerData: Codable, Equatable, Sendable {
    public var title: String
    public var subTitle: String
    public var features: [String]
    public var imageId: String?
    public var selectedDevice: String?
    public var backgroundId: String
    public var opacity: Double

    public init(
        title: String = "Banner Title",
        subTitle: String = "Banner SubTitle",
        features: [String] = [],
        imageId: String? = nil,
        selectedDevice: String? = nil,
        backgroundId: String = "1",
        opacity: Double = 1
    ) {
        self.title = title
        self.subTitle = subTitle
        self.features = features
        self.imageId = imageId
        self.selectedDevice = selectedDevice
        self.backgroundId = backgroundId
        self.opacity = opacity
    }
}

/// Persisted data for the minimal banner template.
public struct MinimalBannerData: Codable, Equatable, Sendable {
    public var title: String
    public var imageId: String?
    public var selectedDevice: String?
    public var backgroundId: String
    public var opacity: Double

    public init(
        title: String = "App Title",
        imageId: String? = nil,
        selectedDevice: String? = nil,
        backgroundId: String = "1",
        opacity: Double = 1
    ) {
        self.title = title
        self.imageId = imageId
        self.selectedDevice = selectedDevice
        self.backgroundId = backgroundId
        self.opacity = opacity
    }
}

public extension BannerFile {
    var classicData: ClassicBannerData? {
        get {
            BannerTemplateDataStore.decode(
                ClassicBannerData.self,
                templateID: BannerTemplateID.classic,
                from: templateData
            )
        }
        set {
            BannerTemplateDataStore.updateEncoded(
                newValue,
                templateID: BannerTemplateID.classic,
                in: &templateData
            )
        }
    }

    var minimalData: MinimalBannerData? {
        get {
            BannerTemplateDataStore.decode(
                MinimalBannerData.self,
                templateID: BannerTemplateID.minimal,
                from: templateData
            )
        }
        set {
            BannerTemplateDataStore.updateEncoded(
                newValue,
                templateID: BannerTemplateID.minimal,
                in: &templateData
            )
        }
    }
}
