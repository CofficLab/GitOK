import Foundation

public struct CoAuthor: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var email: String

    public init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    public var coAuthoredByLine: String {
        "Co-authored-by: \(name) <\(email)>"
    }

    public var displayText: String {
        "\(name) <\(email)>"
    }
}

public final class CoAuthorStore: @unchecked Sendable {
    public static let shared = CoAuthorStore()

    private let userDefaultsKey: String
    private let userDefaults: UserDefaults

    public init(
        userDefaults: UserDefaults = .standard,
        userDefaultsKey: String = "GitOK_CoAuthors"
    ) {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
    }

    public func saveCoAuthors(_ coauthors: [CoAuthor]) {
        if let data = try? JSONEncoder().encode(coauthors) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }

    public func loadCoAuthors() -> [CoAuthor] {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let coauthors = try? JSONDecoder().decode([CoAuthor].self, from: data) else {
            return []
        }
        return coauthors
    }

    public func addCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        if !coauthors.contains(where: { $0.email == coauthor.email }) {
            coauthors.append(coauthor)
            saveCoAuthors(coauthors)
        }
    }

    public func removeCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        coauthors.removeAll { $0.id == coauthor.id }
        saveCoAuthors(coauthors)
    }

    public func updateCoAuthor(_ coauthor: CoAuthor) {
        var coauthors = loadCoAuthors()
        if let index = coauthors.firstIndex(where: { $0.id == coauthor.id }) {
            coauthors[index] = coauthor
            saveCoAuthors(coauthors)
        }
    }
}
