import Foundation

/// 头像用户信息
struct AvatarUser: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?

    init(name: String, email: String, avatarURL: URL? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }

    // MARK: - Equatable

    static func == (lhs: AvatarUser, rhs: AvatarUser) -> Bool {
        lhs.email == rhs.email && lhs.name == rhs.name
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
        hasher.combine(name)
    }
}
