import Foundation

public struct Diff {
    public var message = ""
    public var uuid: String

    public init(message: String = "", uuid: String = UUID().uuidString) {
        self.message = message
        self.uuid = uuid
    }

    public static func fromLine(_ l: String) -> Diff {
        Diff(message: l, uuid: UUID().uuidString)
    }
}

extension Diff: Identifiable {
    public var id: String {
        uuid
    }
}
