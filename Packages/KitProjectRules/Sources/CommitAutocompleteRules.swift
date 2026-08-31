import Foundation

public enum CommitAutocompleteRules {
    public enum CompletionKind: String, Sendable {
        case issue
        case user
        case emoji
    }

    public struct Completion: Identifiable, Equatable, Sendable {
        public let kind: CompletionKind
        public let title: String
        public let detail: String
        public let insertion: String

        public init(kind: CompletionKind, title: String, detail: String, insertion: String) {
            self.kind = kind
            self.title = title
            self.detail = detail
            self.insertion = insertion
        }

        public var id: String {
            "\(kind.rawValue):\(insertion)"
        }
    }

    private struct ActiveToken {
        let trigger: Character
        let query: String
        let range: Range<String.Index>
    }

    private static let defaultEmojiCompletions: [Completion] = [
        Completion(kind: .emoji, title: ":sparkles:", detail: "新功能", insertion: ":sparkles:"),
        Completion(kind: .emoji, title: ":bug:", detail: "修复问题", insertion: ":bug:"),
        Completion(kind: .emoji, title: ":memo:", detail: "文档", insertion: ":memo:"),
        Completion(kind: .emoji, title: ":recycle:", detail: "重构", insertion: ":recycle:"),
        Completion(kind: .emoji, title: ":zap:", detail: "性能", insertion: ":zap:"),
        Completion(kind: .emoji, title: ":white_check_mark:", detail: "测试", insertion: ":white_check_mark:"),
        Completion(kind: .emoji, title: ":lipstick:", detail: "UI 样式", insertion: ":lipstick:"),
        Completion(kind: .emoji, title: ":wrench:", detail: "配置", insertion: ":wrench:"),
    ]

    public static func issueReferences(from branchNames: [String]) -> [String] {
        let patterns = [
            #"(?i)(?:^|[\/_\-#])(?:issue|bug|fix|feat|feature|gh)?[\/_\-#]*([0-9]{1,7})(?=$|[\/_\-])"#,
            #"#([0-9]{1,7})"#,
        ]

        var references: [String] = []
        for branchName in branchNames {
            for pattern in patterns {
                references.append(contentsOf: captureMatches(in: branchName, pattern: pattern).map { "#\($0)" })
            }
        }

        return uniqueSortedReferences(references)
    }

    public static func userMentionCandidates(namesAndEmails: [(name: String, email: String)]) -> [String] {
        let candidates = namesAndEmails.flatMap { name, email -> [String] in
            [
                mentionCandidate(from: name),
                mentionCandidate(from: email.components(separatedBy: "@").first ?? ""),
            ].compactMap { $0 }
        }

        return uniqueSorted(candidates)
    }

    public static func completions(
        for text: String,
        issueReferences: [String],
        userMentions: [String],
        limit: Int = 6
    ) -> [Completion] {
        guard let token = activeToken(in: text) else { return [] }

        let query = token.query.lowercased()
        let matches: [Completion]
        switch token.trigger {
        case "#":
            matches = uniqueSortedReferences(issueReferences).map {
                Completion(kind: .issue, title: $0, detail: "Issue 引用", insertion: $0)
            }
        case "@":
            matches = uniqueSorted(userMentions).map {
                Completion(kind: .user, title: $0, detail: "用户 mention", insertion: $0)
            }
        case ":":
            matches = defaultEmojiCompletions
        default:
            return []
        }

        return matches
            .filter { query.isEmpty || $0.insertion.dropFirst().lowercased().contains(query) }
            .prefix(limit)
            .map { $0 }
    }

    public static func text(_ text: String, applying completion: Completion) -> String {
        guard let token = activeToken(in: text) else { return text }

        var updated = text
        updated.replaceSubrange(token.range, with: completion.insertion)

        if updated.last?.isWhitespace == false {
            updated.append(" ")
        }

        return updated
    }

    private static func activeToken(in text: String) -> ActiveToken? {
        guard let lastNonWhitespaceIndex = text.indices.reversed().first(where: { text[$0].isWhitespace == false }) else {
            return nil
        }

        var start = lastNonWhitespaceIndex
        while start > text.startIndex {
            let previous = text.index(before: start)
            if text[previous].isWhitespace {
                break
            }
            start = previous
        }

        let tokenRange = start..<text.index(after: lastNonWhitespaceIndex)
        guard let trigger = text[tokenRange].first,
              ["#", "@", ":"].contains(trigger) else {
            return nil
        }

        let queryStart = text.index(after: start)
        let query = String(text[queryStart..<tokenRange.upperBound])
        guard query.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }) else {
            return nil
        }

        return ActiveToken(trigger: trigger, query: query, range: tokenRange)
    }

    private static func mentionCandidate(from rawValue: String) -> String? {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let normalized = rawValue
            .lowercased()
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
            .reduce(into: "") { partial, character in
                if character == "-", partial.last == "-" {
                    return
                }
                partial.append(character)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))

        guard normalized.isEmpty == false else { return nil }
        return "@\(normalized)"
    }

    private static func captureMatches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let matchRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[matchRange])
        }
    }

    private static func uniqueSortedReferences(_ references: [String]) -> [String] {
        uniqueSorted(references).sorted { lhs, rhs in
            let lhsNumber = Int(lhs.dropFirst()) ?? Int.max
            let rhsNumber = Int(rhs.dropFirst()) ?? Int.max
            if lhsNumber == rhsNumber { return lhs < rhs }
            return lhsNumber < rhsNumber
        }
    }

    private static func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false })).sorted()
    }
}
