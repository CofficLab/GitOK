import Foundation

public enum CommitAuthorParser {
    public static func performAvatarUsersLoad(
        author: String,
        message: String,
        logStart: () async -> Void,
        logCoAuthors: (Int) async -> Void,
        setUsers: ([AvatarUser]) async -> Void
    ) async {
        await logStart()

        let users = avatarUsers(author: author, message: message)
        if users.count > 1 {
            await logCoAuthors(users.count - 1)
        }

        await setUsers(users)
    }

    public static func avatarUsers(author: String, message: String) -> [AvatarUser] {
        var users = [primaryAuthor(from: author)]
        users.append(contentsOf: coAuthors(from: message))

        var seenEmails = Set<String>()
        var uniqueUsers: [AvatarUser] = []

        for user in users {
            if seenEmails.contains(user.email) == false {
                seenEmails.insert(user.email)
                uniqueUsers.append(user)
            }
        }

        return uniqueUsers
    }

    public static func primaryAuthor(from author: String) -> AvatarUser {
        if let emailRange = author.range(of: "<([^>]+)>", options: .regularExpression) {
            let emailStartIndex = author.index(emailRange.lowerBound, offsetBy: 1)
            let emailEndIndex = author.index(emailRange.upperBound, offsetBy: -1)
            let email = String(author[emailStartIndex ..< emailEndIndex])

            let name = String(author[..<emailRange.lowerBound]).trimmingCharacters(in: .whitespaces)

            return AvatarUser(name: name, email: email)
        }

        return AvatarUser(name: author, email: "")
    }

    public static func coAuthors(from message: String) -> [AvatarUser] {
        var coAuthors: [AvatarUser] = []

        let pattern = #"Co-authored-by:\s*([^<]+?)\s*<([^>]+)>"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(message.startIndex..., in: message)
            let matches = regex.matches(in: message, range: range)

            for match in matches where match.numberOfRanges >= 3 {
                guard let nameRange = Range(match.range(at: 1), in: message),
                      let emailRange = Range(match.range(at: 2), in: message) else {
                    continue
                }

                let name = String(message[nameRange]).trimmingCharacters(in: .whitespaces)
                let email = String(message[emailRange]).trimmingCharacters(in: .whitespaces)

                coAuthors.append(AvatarUser(name: name, email: email))
            }
        }

        return coAuthors
    }
}
