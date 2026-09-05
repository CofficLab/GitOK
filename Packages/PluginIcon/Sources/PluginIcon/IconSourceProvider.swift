import Foundation
import ProjectRulesKit

public enum IconSourceID {
    public static let projectImages = "project-images"
    public static let remoteManifest = "remote-manifest"
}

public struct IconSourceDescriptor: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct IconSourceAsset: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let url: URL
    public let sourceID: String
    public let category: String?

    public init(id: String, title: String, url: URL, sourceID: String, category: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.sourceID = sourceID
        self.category = category
    }
}

public protocol IconSourceProviding: Sendable {
    var sources: [IconSourceDescriptor] { get }
    func assets(for sourceID: String, in projectURL: URL) async throws -> [IconSourceAsset]
}

/// Reads project images locally and the legacy GitOK icon manifest remotely.
public final class DefaultIconSourceProvider: IconSourceProviding, @unchecked Sendable {
    public let sources = [
        IconSourceDescriptor(id: IconSourceID.projectImages, title: "Project Images"),
        IconSourceDescriptor(id: IconSourceID.remoteManifest, title: "GitOK Library"),
    ]

    private let manifestURL: URL
    private let fileManager: FileManager

    public init(
        manifestURL: URL = URL(string: "https://gitok.coffic.cn/icon-manifest.json")!,
        fileManager: FileManager = .default
    ) {
        self.manifestURL = manifestURL
        self.fileManager = fileManager
    }

    public func assets(for sourceID: String, in projectURL: URL) async throws -> [IconSourceAsset] {
        switch sourceID {
        case IconSourceID.projectImages:
            return projectAssets(in: projectURL)
        case IconSourceID.remoteManifest:
            return try await remoteAssets()
        default:
            return []
        }
    }

    private func projectAssets(in projectURL: URL) -> [IconSourceAsset] {
        let directories = [
            projectURL.appendingPathComponent(".gitok/images", isDirectory: true),
            projectURL.appendingPathComponent(".gitok/icons/images", isDirectory: true),
        ]
        return directories.reduce(into: [IconSourceAsset]()) { result, directory in
            guard let entries = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
            result += IconFileRules.imageFileURLs(in: directory, entries: entries).map { url in
                IconSourceAsset(
                    id: url.path,
                    title: url.deletingPathExtension().lastPathComponent,
                    url: url,
                    sourceID: IconSourceID.projectImages
                )
            }
        }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private func remoteAssets() async throws -> [IconSourceAsset] {
        let (data, response) = try await URLSession.shared.data(from: manifestURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw IconSourceError.networkFailure
        }

        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        return manifest.iconsByCategory.flatMap { category, icons in
            icons.compactMap { item in
                guard let url = URL(string: item.path, relativeTo: manifestURL.deletingLastPathComponent()) else { return nil }
                return IconSourceAsset(
                    id: url.absoluteString,
                    title: item.name,
                    url: url,
                    sourceID: IconSourceID.remoteManifest,
                    category: category
                )
            }
        }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

public struct IconManifest: Codable, Sendable {
    public let iconsByCategory: [String: [IconManifestItem]]

    public init(iconsByCategory: [String: [IconManifestItem]]) {
        self.iconsByCategory = iconsByCategory
    }
}

public struct IconManifestItem: Codable, Sendable {
    public let name: String
    public let path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

public enum IconSourceError: Error, LocalizedError, Equatable {
    case networkFailure

    public var errorDescription: String? {
        switch self {
        case .networkFailure: "Unable to load the GitOK icon library."
        }
    }
}
