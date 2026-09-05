import BannerCoreKit
import Foundation
import ProjectRulesKit

/// Persists banner JSON documents inside a project's `.gitok/banners` folder.
public final class BannerRepository: @unchecked Sendable {
    public static let bannerStoragePath = ".gitok/banners"

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
    }

    public func getBanners(from projectURL: URL) -> [BannerFile] {
        let directoryURL = Self.bannerDirectoryURL(for: projectURL)
        return BannerRepositoryIndex.loadModels(
            from: directoryURL,
            fileManager: fileManager,
            load: { [decoder, fileManager] fileURL in
                guard let data = try? Data(contentsOf: fileURL, options: [.mappedIfSafe]),
                      var banner = try? decoder.decode(BannerFile.self, from: data) else {
                    return nil
                }
                banner.path = fileURL.path
                banner.projectURL = projectURL
                _ = fileManager
                return banner
            },
            sort: { $0.id < $1.id }
        )
    }

    public func getBanner(by id: String, from projectURL: URL) -> BannerFile? {
        getBanners(from: projectURL).first { $0.id == id }
    }

    @discardableResult
    public func createBanner(
        in projectURL: URL,
        now: Date = Date()
    ) throws -> BannerFile {
        let directoryURL = Self.bannerDirectoryURL(for: projectURL)
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        var fileURL = directoryURL.appendingPathComponent(
            BannerStorageRules.newBannerFileName(now: now)
        )
        var suffix = 1
        while fileManager.fileExists(atPath: fileURL.path) {
            fileURL = directoryURL.appendingPathComponent(
                "\(fileURL.deletingPathExtension().lastPathComponent)_\(suffix).json"
            )
            suffix += 1
        }

        let banner = BannerFile(path: fileURL.path, projectURL: projectURL)
        try save(banner)
        return banner
    }

    public func save(_ banner: BannerFile) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try encoder.encode(banner)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func delete(_ banner: BannerFile) throws {
        try fileManager.removeItem(at: URL(fileURLWithPath: banner.path))
    }

    public static func bannerDirectoryURL(for projectURL: URL) -> URL {
        BannerStorageRules.bannerDirectoryURL(
            projectPath: projectURL.path,
            storagePath: bannerStoragePath
        )
    }
}
