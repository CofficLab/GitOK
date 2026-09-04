import Foundation

/// `.git` 目录内部状态的指纹集合。
///
/// 用于对比两次读取是否发生变化，从而区分「HEAD 切换 / 暂存区改动 / stash 变化 /
/// refs 变化」。每个字段为对应目录 / 文件的内容指纹（字符串形式）；任一为 `nil`
/// 表示读取失败（例如目录不存在）。
///
/// 对齐旧版 `GitDirectorySnapshot`：
/// - `head`：当前 HEAD 指向的 commit hash（解析符号引用到实际 hash）；
/// - `index`：`.git/index` 的内容指纹（暂存区）；
/// - `stash`：`refs/stash` + `logs/refs/stash` 的联合指纹；
/// - `refs`：`refs/heads` / `refs/remotes` / `refs/tags` / `packed-refs` 的联合指纹。
struct GitDirectorySnapshot: Equatable, Sendable {
    let head: String?
    let index: String?
    let stash: String?
    let refs: String?
}

/// `.git` 目录解析器：
/// - 支持 worktree（`.git` 是文件、内含 `gitdir:` 行指向真实 git 目录）；
/// - 读取 HEAD / index / stash / refs 的指纹，用于快照对比。
enum GitDirectoryResolver {

    enum ResolverError: Error, Equatable, Sendable {
        case gitDirectoryNotFound(String)
        case invalidGitFile(String)
    }

    /// 解析项目根目录对应的真实 git 目录 URL。
    ///
    /// 普通仓库：返回 `<projectURL>/.git`；
    /// worktree：`.git` 是文件，读取其 `gitdir: <path>` 行并解析为绝对路径。
    static func resolveGitDirectory(for projectURL: URL) throws -> URL {
        let dotGitURL = projectURL.appendingPathComponent(".git")

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dotGitURL.path, isDirectory: &isDirectory) else {
            throw ResolverError.gitDirectoryNotFound(dotGitURL.path)
        }

        if isDirectory.boolValue {
            return dotGitURL
        }

        let content = try String(contentsOf: dotGitURL, encoding: .utf8)
        guard let gitDirLine = content
            .split(separator: "\n")
            .first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("gitdir:") })
        else {
            throw ResolverError.invalidGitFile(dotGitURL.path)
        }

        let rawPath = gitDirLine
            .replacingOccurrences(of: "gitdir:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if rawPath.hasPrefix("/") {
            return URL(fileURLWithPath: rawPath, isDirectory: true)
        }

        return projectURL.appendingPathComponent(rawPath).standardizedFileURL
    }

    /// 读取 HEAD 指向的 commit hash（解析符号引用）。
    static func readHeadHash(gitDirectory: URL) -> String? {
        let headURL = gitDirectory.appendingPathComponent("HEAD")
        guard let headContent = try? String(contentsOf: headURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
            headContent.isEmpty == false
        else {
            return nil
        }

        guard headContent.hasPrefix("ref:") else {
            return headContent
        }

        let refPath = headContent
            .replacingOccurrences(of: "ref:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let refURL = gitDirectory.appendingPathComponent(refPath)
        if let refHash = try? String(contentsOf: refURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
            refHash.isEmpty == false {
            return refHash
        }

        return readPackedRef(gitDirectory: gitDirectory, refPath: refPath)
    }

    /// 读取当前 `.git` 目录的四维指纹快照。
    static func readSnapshot(gitDirectory: URL) -> GitDirectorySnapshot {
        GitDirectorySnapshot(
            head: readHeadHash(gitDirectory: gitDirectory),
            index: fileContentFingerprint(gitDirectory.appendingPathComponent("index")),
            stash: stashFingerprint(gitDirectory: gitDirectory),
            refs: refsFingerprint(gitDirectory: gitDirectory)
        )
    }

    // MARK: - Fingerprint primitives

    /// 单个文件的内容指纹：`<size>:<FNV-1a hex>`。
    ///
    /// 用尺寸 + 哈希双保险：尺寸变化必然触发对比；内容相同但路径变化不会误判。
    static func fileContentFingerprint(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        return "\(data.count):\(String(hash, radix: 16))"
    }

    private static func stashFingerprint(gitDirectory: URL) -> String? {
        let refsStash = fileContentFingerprint(gitDirectory.appendingPathComponent("refs/stash"))
        let logsStash = fileContentFingerprint(gitDirectory.appendingPathComponent("logs/refs/stash"))

        switch (refsStash, logsStash) {
        case (nil, nil):
            return nil
        case let (refs?, nil):
            return refs
        case let (nil, logs?):
            return logs
        case let (refs?, logs?):
            return "\(refs):\(logs)"
        }
    }

    private static func refsFingerprint(gitDirectory: URL) -> String? {
        let fingerprints = [
            directoryContentFingerprint(gitDirectory.appendingPathComponent("refs/heads")),
            directoryContentFingerprint(gitDirectory.appendingPathComponent("refs/remotes")),
            directoryContentFingerprint(gitDirectory.appendingPathComponent("refs/tags")),
            fileContentFingerprint(gitDirectory.appendingPathComponent("packed-refs"))
        ].compactMap { $0 }

        guard fingerprints.isEmpty == false else { return nil }
        return fingerprints.joined(separator: "|")
    }

    private static func directoryContentFingerprint(_ url: URL) -> String? {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var entries: [String] = []
        for case let fileURL as URL in enumerator {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                continue
            }

            let relativePath = String(fileURL.path.dropFirst(url.path.count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let fingerprint = fileContentFingerprint(fileURL) else { continue }
            entries.append("\(relativePath)=\(fingerprint)")
        }

        guard entries.isEmpty == false else { return nil }
        return entries.sorted().joined(separator: ";")
    }

    private static func readPackedRef(gitDirectory: URL, refPath: String) -> String? {
        let packedRefsURL = gitDirectory.appendingPathComponent("packed-refs")
        guard let content = try? String(contentsOf: packedRefsURL, encoding: .utf8) else {
            return nil
        }

        for line in content.split(separator: "\n") {
            guard line.hasPrefix("#") == false, line.hasPrefix("^") == false else { continue }
            let parts = line.split(separator: " ")
            guard parts.count == 2, parts[1] == refPath else { continue }
            return String(parts[0])
        }

        return nil
    }
}
