import Foundation

public enum GitParsers {
    public static func parseStashList(_ output: String) -> [GitStashEntry] {
        guard output.isEmpty == false else { return [] }

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let parts = line.split(separator: "\u{1F}", maxSplits: 2, omittingEmptySubsequences: false)
                guard let ref = parts.first,
                      let start = ref.firstIndex(of: "{"),
                      let end = ref.firstIndex(of: "}"),
                      let index = Int(ref[ref.index(after: start)..<end]) else {
                    return nil
                }

                let rawMessage = parts.count > 2 ? String(parts[2]) : (parts.count > 1 ? String(parts[1]) : "")
                let message = normalizeStashMessage(rawMessage)
                let relativeDate = parts.count > 2 ? String(parts[1]) : nil
                return GitStashEntry(
                    index: index,
                    message: message,
                    branchName: parseStashBranchName(rawMessage),
                    relativeDate: relativeDate?.isEmpty == false ? relativeDate : nil
                )
            }
    }

    public static func parseStatusEntries(_ output: String) -> [GitStatusEntry] {
        guard output.isEmpty == false else { return [] }

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { rawLine in
                let line = String(rawLine)
                guard line.count >= 4 else { return nil }

                let chars = Array(line)
                let path = String(line.dropFirst(3))
                return GitStatusEntry(
                    path: path,
                    indexStatus: chars[0],
                    workTreeStatus: chars[1]
                )
            }
    }

    public static func parseAheadBehindCounts(_ output: String) -> (ahead: Int, behind: Int)? {
        let counts = output
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .compactMap { Int($0) }

        guard counts.count >= 2 else { return nil }
        return (ahead: counts[0], behind: counts[1])
    }

    public static func classifyMergeFiles(
        unresolvedPaths: Set<String>,
        statusEntries: [GitStatusEntry]
    ) -> [GitMergeFile] {
        let entryByPath = Dictionary(uniqueKeysWithValues: statusEntries.map { ($0.path, $0) })
        let allPaths = unresolvedPaths.union(entryByPath.keys).sorted()

        return allPaths.map { path in
            if unresolvedPaths.contains(path) {
                return GitMergeFile(path: path, state: .unresolved)
            }

            let entry = entryByPath[path]!

            if entry.workTreeStatus != " " {
                return GitMergeFile(path: path, state: .pendingStage)
            }

            return GitMergeFile(path: path, state: .staged)
        }
    }

    private static func normalizeStashMessage(_ message: String) -> String {
        guard message.hasPrefix("On "),
              let separator = message.firstIndex(of: ":") else {
            return message
        }

        let contentStart = message.index(after: separator)
        let normalized = message[contentStart...].trimmingCharacters(in: .whitespaces)
        return normalized.isEmpty ? message : normalized
    }

    private static func parseStashBranchName(_ message: String) -> String? {
        let prefixes = ["On ", "WIP on "]
        guard let prefix = prefixes.first(where: { message.hasPrefix($0) }),
              let separator = message.firstIndex(of: ":") else {
            return nil
        }

        let branchStart = message.index(message.startIndex, offsetBy: prefix.count)
        let branchName = message[branchStart..<separator].trimmingCharacters(in: .whitespaces)
        return branchName.isEmpty ? nil : branchName
    }
}
