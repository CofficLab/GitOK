import CoreServices
import Foundation

struct GitDirectorySnapshot: Equatable, Sendable {
    let head: String?
    let index: String?
    let stash: String?
    let refs: String?
}

enum GitDirectoryWatcherError: Error, Equatable {
    case gitDirectoryNotFound(String)
    case invalidGitFile(String)
    case streamCreationFailed(String)
}

final class GitDirectoryWatcher {
    private let url: URL
    private let onChange: @Sendable () -> Void
    private var stream: FSEventStreamRef?

    init(url: URL, onChange: @escaping @Sendable () -> Void) throws {
        self.url = url
        self.onChange = onChange
        try start()
    }

    deinit {
        stop()
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private func start() throws {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<GitDirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.onChange()
        }

        let paths = [url.path] as CFArray
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        ) else {
            throw GitDirectoryWatcherError.streamCreationFailed(url.path)
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }
}

enum GitDirectoryResolver {
    static func resolveGitDirectory(for projectURL: URL) throws -> URL {
        let dotGitURL = projectURL.appendingPathComponent(".git")

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dotGitURL.path, isDirectory: &isDirectory) else {
            throw GitDirectoryWatcherError.gitDirectoryNotFound(dotGitURL.path)
        }

        if isDirectory.boolValue {
            return dotGitURL
        }

        let content = try String(contentsOf: dotGitURL, encoding: .utf8)
        guard let gitDirLine = content
            .split(separator: "\n")
            .first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("gitdir:") })
        else {
            throw GitDirectoryWatcherError.invalidGitFile(dotGitURL.path)
        }

        let rawPath = gitDirLine
            .replacingOccurrences(of: "gitdir:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if rawPath.hasPrefix("/") {
            return URL(fileURLWithPath: rawPath, isDirectory: true)
        }

        return projectURL.appendingPathComponent(rawPath).standardizedFileURL
    }

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

    static func readSnapshot(gitDirectory: URL) -> GitDirectorySnapshot {
        GitDirectorySnapshot(
            head: readHeadHash(gitDirectory: gitDirectory),
            index: fileContentFingerprint(gitDirectory.appendingPathComponent("index")),
            stash: stashFingerprint(gitDirectory: gitDirectory),
            refs: refsFingerprint(gitDirectory: gitDirectory)
        )
    }

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

            let relativePath = String(fileURL.path.dropFirst(url.path.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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
