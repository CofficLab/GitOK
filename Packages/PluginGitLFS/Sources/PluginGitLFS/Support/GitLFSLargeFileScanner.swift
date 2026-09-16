import Foundation

enum GitLFSLargeFileScanner {
    /// 递归扫描工作区（跳过 `.git` 与常见构建目录），返回超过阈值的文件相对路径。
    static func scan(
        in projectURL: URL,
        thresholdBytes: Int64,
        shouldCancel: @Sendable () -> Bool
    ) -> [String] {
        guard !shouldCancel() else { return [] }

        let fileManager = FileManager.default
        let rootPath = projectURL.resolvingSymlinksInPath().standardizedFileURL.path
        let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey]
        let skipped: Set<String> = [".git", "node_modules", "DerivedData", ".build", "Pods", "build"]
        var results: [String] = []
        guard let enumerator = fileManager.enumerator(
            at: projectURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            guard !shouldCancel() else { return [] }

            let last = url.lastPathComponent
            if skipped.contains(last) {
                enumerator.skipDescendants()
                continue
            }
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isDirectory == true { continue }
            if values.isRegularFile == true, let size = values.fileSize, Int64(size) > thresholdBytes {
                let filePath = url.resolvingSymlinksInPath().standardizedFileURL.path
                guard filePath.hasPrefix(rootPrefix) else { continue }
                results.append(String(filePath.dropFirst(rootPrefix.count)))
                if results.count >= 200 { break }
            }
        }
        return shouldCancel() ? [] : results
    }
}
