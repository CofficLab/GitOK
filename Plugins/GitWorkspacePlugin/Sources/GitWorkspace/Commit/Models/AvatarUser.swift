import Foundation

/// 头像用户信息
public struct AvatarUser: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let email: String
    public let avatarURL: URL?

    public init(name: String, email: String, avatarURL: URL? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }

    // MARK: - Equatable

    public static func == (lhs: AvatarUser, rhs: AvatarUser) -> Bool {
        lhs.email == rhs.email && lhs.name == rhs.name
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(email)
        hasher.combine(name)
    }
}
