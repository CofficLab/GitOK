import Foundation

/// Persisted project icon configuration, compatible with the legacy `.gitok/icons` JSON files.
public struct IconData: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var title: String
    public var iconId: String
    public var backgroundId: String
    public var imageURL: URL?
    public var path: String
    public var opacity: Double
    public var scale: Double?
    public var cornerRadius: Double
    public var padding: Double

    public var id: String { path }

    public init(
        title: String = "1",
        iconId: String = "1",
        backgroundId: String = "3",
        imageURL: URL? = nil,
        path: String,
        opacity: Double = 1,
        scale: Double? = 1,
        cornerRadius: Double = 0,
        padding: Double = 0.12
    ) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.path = path
        self.opacity = opacity
        self.scale = scale
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    private enum CodingKeys: String, CodingKey {
        case title, iconId, backgroundId, imageURL, opacity, scale, cornerRadius, padding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        if let integerID = try? container.decode(Int.self, forKey: .iconId) {
            iconId = String(integerID)
        } else {
            iconId = try container.decode(String.self, forKey: .iconId)
        }
        backgroundId = try container.decode(String.self, forKey: .backgroundId)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
        scale = try container.decodeIfPresent(Double.self, forKey: .scale)
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 0
        padding = try container.decodeIfPresent(Double.self, forKey: .padding) ?? 0.12
        path = ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(iconId, forKey: .iconId)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(opacity, forKey: .opacity)
        try container.encodeIfPresent(scale, forKey: .scale)
        try container.encode(cornerRadius, forKey: .cornerRadius)
        try container.encode(padding, forKey: .padding)
    }
}
