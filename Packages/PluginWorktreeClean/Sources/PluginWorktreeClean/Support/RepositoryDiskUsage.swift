import CryptoKit
import Foundation
import KitGit

struct RepositoryDiskUsageCacheValue: Codable, Equatable, Sendable {
    let repositoryPath: String
    let measuredAt: Date
    let byteCount: Int64
}

struct RepositoryDiskUsageCache: Sendable {
    static let maximumAge: TimeInterval = 5 * 60

    private let directoryURL: URL

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL()
    }

    func load(at repositoryURL: URL) -> RepositoryDiskUsageCacheValue? {
        let repositoryPath = repositoryURL.standardizedFileURL.path
        let fileURL = cacheFileURL(for: repositoryPath)
        guard let data = try? Data(contentsOf: fileURL),
              let value = try? JSONDecoder().decode(RepositoryDiskUsageCacheValue.self, from: data),
              value.repositoryPath == repositoryPath,
              value.byteCount >= 0 else {
            return nil
        }
        return value
    }

    func store(_ byteCount: Int64, at repositoryURL: URL, measuredAt: Date = Date()) {
        guard byteCount >= 0 else { return }
        let repositoryPath = repositoryURL.standardizedFileURL.path
        let value = RepositoryDiskUsageCacheValue(
            repositoryPath: repositoryPath,
            measuredAt: measuredAt,
            byteCount: byteCount
        )
        guard let data = try? JSONEncoder().encode(value) else { return }

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: cacheFileURL(for: repositoryPath), options: .atomic)
        } catch {
            // A cache is an optimization; an unwritable cache must not affect GitOK.
        }
    }

    private func cacheFileURL(for repositoryPath: String) -> URL {
        let digest = SHA256.hash(data: Data(repositoryPath.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directoryURL.appendingPathComponent("\(digest).json")
    }

    private static func defaultDirectoryURL() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (caches ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("com.coffic.gitok", isDirectory: true)
            .appendingPathComponent("repository-disk-usage", isDirectory: true)
    }
}

/// Calculates the physical file space occupied by a repository directory.
///
/// Hidden files, including `.git`, are included. Symbolic-link targets are not
/// traversed, so a link to a directory outside the repository cannot inflate
/// the reported size.
enum RepositoryDiskUsage {
    static func calculate(
        at repositoryURL: URL,
        cancellation: GitProcessCancellation? = nil
    ) -> Int64? {
        if cancellation?.isCancelled == true { return nil }
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .fileAllocatedSizeKey,
        ]

        guard (try? repositoryURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
              let enumerator = fileManager.enumerator(
                  at: repositoryURL,
                  includingPropertiesForKeys: Array(resourceKeys),
                  options: []
              ) else {
            return nil
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if cancellation?.isCancelled == true { return nil }
            guard let values = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                return nil
            }
            guard values.isDirectory != true, values.isRegularFile == true,
                  let allocatedSize = values.fileAllocatedSize else {
                continue
            }

            let (newTotal, overflow) = total.addingReportingOverflow(Int64(allocatedSize))
            guard !overflow else { return nil }
            total = newTotal
        }

        return total
    }
}
