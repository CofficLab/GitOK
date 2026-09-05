import Foundation

public struct GitBranchCompareCommit: Identifiable, Equatable, Sendable {
    public let hash: String
    public let author: String
    public let date: Date
    public let subject: String

    public init(hash: String, author: String, date: Date, subject: String) {
        self.hash = hash
        self.author = author
        self.date = date
        self.subject = subject
    }

    public var id: String { hash }
}

public struct GitBranchCompareFile: Identifiable, Equatable, Sendable {
    public let status: String
    public let path: String
    public let oldPath: String?

    public init(status: String, path: String, oldPath: String? = nil) {
        self.status = status
        self.path = path
        self.oldPath = oldPath
    }

    public var id: String {
        if let oldPath {
            return "\(status):\(oldPath)->\(path)"
        }
        return "\(status):\(path)"
    }
}

public struct GitBranchCompare: Equatable, Sendable {
    public let base: String
    public let head: String
    public let ahead: Int
    public let behind: Int
    public let commits: [GitBranchCompareCommit]
    public let files: [GitBranchCompareFile]

    public init(
        base: String,
        head: String,
        ahead: Int,
        behind: Int,
        commits: [GitBranchCompareCommit],
        files: [GitBranchCompareFile]
    ) {
        self.base = base
        self.head = head
        self.ahead = ahead
        self.behind = behind
        self.commits = commits
        self.files = files
    }
}

public enum GitBranchCompareOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidBranch
        case compareFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidBranch:
                LumiPluginLocalization.string("Two branches are required for comparison.", bundle: .module)
            case .compareFailed(let message):
                String(format: LumiPluginLocalization.string("Branch comparison failed: %@", bundle: .module), message)
            }
        }
    }

    public static func compare(
        base: String,
        head: String,
        in repository: URL
    ) throws -> GitBranchCompare {
        let baseName = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let headName = head.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseName.isEmpty, !headName.isEmpty, baseName != headName else {
            throw Error.invalidBranch
        }

        do {
            _ = try GitProcessRunner.run(["rev-parse", "--verify", "\(baseName)^{commit}"], in: repository)
            _ = try GitProcessRunner.run(["rev-parse", "--verify", "\(headName)^{commit}"], in: repository)

            let counts = try GitProcessRunner.run(
                ["rev-list", "--left-right", "--count", "\(baseName)...\(headName)"],
                in: repository
            )
            let countParts = counts.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard countParts.count == 2,
                  let behind = Int(countParts[0]),
                  let ahead = Int(countParts[1]) else {
                throw Error.compareFailed("Unable to parse branch counts.")
            }

            let commits = try loadCommits(base: baseName, head: headName, in: repository)
            let files = try loadFiles(base: baseName, head: headName, in: repository)
            return GitBranchCompare(
                base: baseName,
                head: headName,
                ahead: ahead,
                behind: behind,
                commits: commits,
                files: files
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.compareFailed(Self.message(for: error))
        }
    }

    private static func loadCommits(
        base: String,
        head: String,
        in repository: URL
    ) throws -> [GitBranchCompareCommit] {
        let separator = "\u{1f}"
        let output = try GitProcessRunner.run(
            ["log", "--format=%H%x1f%an%x1f%aI%x1f%s", "\(base)..\(head)"],
            in: repository
        )
        let formatter = ISO8601DateFormatter()
        return output.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            let fields = line.split(separator: Character(separator), omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 4,
                  let date = formatter.date(from: fields[2]) else {
                return nil
            }
            return GitBranchCompareCommit(
                hash: fields[0],
                author: fields[1],
                date: date,
                subject: fields[3]
            )
        }
    }

    private static func loadFiles(
        base: String,
        head: String,
        in repository: URL
    ) throws -> [GitBranchCompareFile] {
        let output = try GitProcessRunner.run(
            ["diff", "--name-status", "--find-renames", "-z", "\(base)...\(head)"],
            in: repository
        )
        let fields = output.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)
        var result: [GitBranchCompareFile] = []
        var index = 0
        while index < fields.count {
            let rawStatus = fields[index]
            guard !rawStatus.isEmpty, index + 1 < fields.count else { break }
            let status = String(rawStatus.prefix(1))
            if status == "R" || status == "C" {
                guard index + 2 < fields.count else { break }
                result.append(GitBranchCompareFile(status: status, path: fields[index + 2], oldPath: fields[index + 1]))
                index += 3
            } else {
                result.append(GitBranchCompareFile(status: status, path: fields[index + 1]))
                index += 2
            }
        }
        return result
    }

    private static func message(for error: Swift.Error) -> String {
        (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
    }
}
