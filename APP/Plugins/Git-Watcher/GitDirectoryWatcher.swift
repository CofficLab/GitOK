import CoreServices
import Foundation

enum GitDirectoryWatcherError: Error {
    case gitDirectoryNotFound(String)
    case invalidGitFile(String)
    case streamCreationFailed(String)
}

final class GitDirectoryWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var stream: FSEventStreamRef?

    init(url: URL, onChange: @escaping () -> Void) throws {
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
    static func resolveGitDirectory(for projectPath: String) throws -> URL {
        let projectURL = URL(fileURLWithPath: projectPath, isDirectory: true)
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
            !headContent.isEmpty
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
            !refHash.isEmpty
        {
            return refHash
        }

        return readPackedRef(gitDirectory: gitDirectory, refPath: refPath)
    }

    private static func readPackedRef(gitDirectory: URL, refPath: String) -> String? {
        let packedRefsURL = gitDirectory.appendingPathComponent("packed-refs")
        guard let content = try? String(contentsOf: packedRefsURL, encoding: .utf8) else {
            return nil
        }

        for line in content.split(separator: "\n") {
            guard !line.hasPrefix("#"), !line.hasPrefix("^") else { continue }
            let parts = line.split(separator: " ")
            guard parts.count == 2, parts[1] == refPath else { continue }
            return String(parts[0])
        }

        return nil
    }
}
