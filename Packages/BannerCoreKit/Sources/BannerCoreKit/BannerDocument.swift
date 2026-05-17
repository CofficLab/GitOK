import Foundation

public struct BannerDocument: Codable, Equatable, Sendable {
    public var templateData: [String: String]
    public var lastSelectedTemplateId: String

    public init(
        templateData: [String: String] = [:],
        lastSelectedTemplateId: String = ""
    ) {
        self.templateData = templateData
        self.lastSelectedTemplateId = lastSelectedTemplateId
    }

    public func templateDataValue(for templateId: String) -> String? {
        templateData[templateId]
    }

    public mutating func setTemplateDataValue(_ data: String, for templateId: String) {
        templateData[templateId] = data
    }
}
