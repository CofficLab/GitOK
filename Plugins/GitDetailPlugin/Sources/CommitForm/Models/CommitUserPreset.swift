import Foundation

public struct CommitUserPreset: Identifiable, Hashable, Sendable {
    public static let recentConfigLimit = 10

    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    public static func presets<ID>(configs: [(id: ID, name: String, email: String)]) -> [CommitUserPreset] {
        configs.map { config in
            CommitUserPreset(
                id: String(describing: config.id),
                name: config.name,
                email: config.email
            )
        }
    }

    public func matchesConfig<ID>(id configID: ID, name configName: String, email configEmail: String) -> Bool {
        id == String(describing: configID) || (name == configName && email == configEmail)
    }

    public static func isSameUser(
        currentName: String,
        currentEmail: String,
        candidateName: String,
        candidateEmail: String
    ) -> Bool {
        currentName == candidateName && currentEmail == candidateEmail
    }
}
