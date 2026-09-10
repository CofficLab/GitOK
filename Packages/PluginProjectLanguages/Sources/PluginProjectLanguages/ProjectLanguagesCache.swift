import CryptoKit
import Foundation
import ProviderProjectLanguages

struct ProjectLanguagesCacheKey: Codable, Equatable, Hashable, Sendable {
    let repositoryPath: String
    let headHash: String
    let analyzerVersion: Int

    init(repositoryPath: String, headHash: String, analyzerVersion: Int) {
        self.repositoryPath = repositoryPath
        self.headHash = headHash
        self.analyzerVersion = analyzerVersion
    }
}

/// Disk-backed cache for clean repository language snapshots.
struct ProjectLanguagesCache: Sendable {
    private struct Entry: Codable, Sendable {
        let key: ProjectLanguagesCacheKey
        let snapshot: ProjectLanguagesSnapshot
    }

    private let directoryURL: URL

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL()
    }

    func load(for key: ProjectLanguagesCacheKey) -> ProjectLanguagesSnapshot? {
        let fileURL = cacheFileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              entry.key == key,
              entry.snapshot.repositoryPath == key.repositoryPath else {
            return nil
        }
        return entry.snapshot
    }

    func store(_ snapshot: ProjectLanguagesSnapshot, for key: ProjectLanguagesCacheKey) {
        let entry = Entry(key: key, snapshot: snapshot)
        guard let data = try? JSONEncoder().encode(entry) else { return }

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: cacheFileURL(for: key), options: .atomic)
        } catch {
            // A cache is an optimization; an unwritable cache must not affect GitOK.
        }
    }

    private func cacheFileURL(for key: ProjectLanguagesCacheKey) -> URL {
        let material = "\(key.repositoryPath)\n\(key.headHash)\n\(key.analyzerVersion)"
        let digest = SHA256.hash(data: Data(material.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directoryURL.appendingPathComponent("\(digest).json")
    }

    private static func defaultDirectoryURL() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (caches ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("com.coffic.gitok", isDirectory: true)
            .appendingPathComponent("project-languages", isDirectory: true)
    }
}
