import BannerCoreKit
import Foundation

/// A persisted banner document together with the project that owns it.
public struct BannerFile: Codable, Equatable, Identifiable, Sendable {
    public var projectURL: URL
    public var record: BannerRecord

    public init(
        path: String,
        projectURL: URL,
        templateData: [String: String] = [:],
        lastSelectedTemplateId: String = ""
    ) {
        self.projectURL = projectURL
        self.record = BannerRecord(
            path: path,
            document: BannerDocument(
                templateData: templateData,
                lastSelectedTemplateId: lastSelectedTemplateId
            )
        )
    }

    public var id: String { record.id }
    public var path: String {
        get { record.path }
        set { record.path = newValue }
    }
    public var document: BannerDocument {
        get { record.document }
        set { record.document = newValue }
    }
    public var templateData: [String: String] {
        get { document.templateData }
        set { document.templateData = newValue }
    }
    public var lastSelectedTemplateId: String {
        get { document.lastSelectedTemplateId }
        set { document.lastSelectedTemplateId = newValue }
    }

    public func getTemplateData(_ templateId: String) -> String? {
        document.templateDataValue(for: templateId)
    }

    public mutating func setTemplateData(_ templateID: String, data: String) {
        document.setTemplateDataValue(data, for: templateID)
    }

    public init(from decoder: Decoder) throws {
        self.projectURL = URL(fileURLWithPath: "/")
        self.record = try BannerRecord(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try record.encode(to: encoder)
    }
}
