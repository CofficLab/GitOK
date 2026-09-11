import Foundation

/// Calculates the physical file space occupied by a repository directory.
///
/// Hidden files, including `.git`, are included. Symbolic-link targets are not
/// traversed, so a link to a directory outside the repository cannot inflate
/// the reported size.
enum RepositoryDiskUsage {
    static func calculate(at repositoryURL: URL) -> Int64? {
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
