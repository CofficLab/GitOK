import Foundation

public struct BannerRecord: Codable, Equatable, Identifiable, Sendable {
    public var path: String
    public var document: BannerDocument

    public init(
        path: String,
        document: BannerDocument = BannerDocument()
    ) {
        self.path = path
        self.document = document
    }

    public var id: String {
        path
    }
}
