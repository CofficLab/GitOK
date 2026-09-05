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

    /// Copies a user-selected image into the banner-owned project storage.
    @discardableResult
    public func importImage(from sourceURL: URL, for projectURL: URL) throws -> String {
        let imagesDirectory = Self.bannerDirectoryURL(for: projectURL)
            .appendingPathComponent("images", isDirectory: true)
        try fileManager.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
        let fileName = "\(UUID().uuidString).\(ext)"
        let destinationURL = imagesDirectory.appendingPathComponent(fileName)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return ".gitok/banners/images/\(fileName)"
    }

    public func imageURL(for imageID: String, in projectURL: URL) -> URL {
        if imageID.hasPrefix("file://") {
            return URL(string: imageID) ?? projectURL
        }
        if imageID.hasPrefix("/") {
            let absoluteURL = URL(fileURLWithPath: imageID)
            if fileManager.fileExists(atPath: absoluteURL.path) {
                return absoluteURL
            }
            return projectURL.appendingPathComponent(String(imageID.dropFirst()))
        }
        return projectURL.appendingPathComponent(imageID)
    }

    public func imageID(for imageURL: URL, projectURL: URL?) -> String {
        guard let projectURL else { return imageURL.path }
        let projectPath = projectURL.standardizedFileURL.path
        let imagePath = imageURL.standardizedFileURL.path
        guard imagePath.hasPrefix(projectPath + "/") else { return imagePath }
        return String(imagePath.dropFirst(projectPath.count + 1))
    }

    public static func bannerDirectoryURL(for projectURL: URL) -> URL {
        BannerStorageRules.bannerDirectoryURL(
            projectPath: projectURL.path,
            storagePath: bannerStoragePath
        )
    }
}
