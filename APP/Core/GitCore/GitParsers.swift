import Foundation

enum GitParsers {
    static func parseStashList(_ output: String) -> [GitStashEntry] {
        guard output.isEmpty == false else { return [] }

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let parts = line.split(separator: "\u{1F}", maxSplits: 1, omittingEmptySubsequences: false)
                guard let ref = parts.first,
                      let start = ref.firstIndex(of: "{"),
                      let end = ref.firstIndex(of: "}"),
                      let index = Int(ref[ref.index(after: start)..<end]) else {
                    return nil
                }

                let message = parts.count > 1 ? normalizeStashMessage(String(parts[1])) : ""
                return GitStashEntry(index: index, message: message)
            }
    }

    static func parseStatusEntries(_ output: String) -> [GitStatusEntry] {
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

    static func classifyMergeFiles(
        unresolvedPaths: Set<String>,
        statusEntries: [GitStatusEntry]
    ) -> [GitMergeFile] {
        let entryByPath = Dictionary(uniqueKeysWithValues: statusEntries.map { ($0.path, $0) })
        let allPaths = unresolvedPaths.union(entryByPath.keys).sorted()

        return allPaths.map { path in
            if unresolvedPaths.contains(path) {
                return GitMergeFile(path: path, state: .unresolved)
            }

            guard let entry = entryByPath[path] else {
                return GitMergeFile(path: path, state: .staged)
            }

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
}
