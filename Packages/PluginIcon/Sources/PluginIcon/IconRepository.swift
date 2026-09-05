import Foundation
import ProjectRulesKit

/// Persists project icon configurations and imported source images.
public final class IconRepository: @unchecked Sendable {
    public static let iconStoragePath = ".gitok/icons"
    public static let imageDirectoryName = "images"

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

    public func getIcons(from projectURL: URL) -> [IconData] {
        let directoryURL = Self.iconDirectoryURL(for: projectURL)
        return loadJSONFiles(in: directoryURL)
    }

    public func createIcon(in projectURL: URL, title: String = "New Icon") throws -> IconData {
        let directoryURL = Self.iconDirectoryURL(for: projectURL)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("\(UUID().uuidString).json")
        let icon = IconData(title: title, path: fileURL.path)
        try save(icon)
        return icon
    }

    public func save(_ icon: IconData) throws {
        let fileURL = URL(fileURLWithPath: icon.path)
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let outputEncoder = self.encoder
        outputEncoder.outputFormatting = .sortedKeys
        try outputEncoder.encode(icon).write(to: fileURL, options: [.atomic])
    }

    public func delete(_ icon: IconData) throws {
        try fileManager.removeItem(at: URL(fileURLWithPath: icon.path))
    }

    public func importImage(_ sourceURL: URL, for projectURL: URL) throws -> URL {
        try importImageData(Data(contentsOf: sourceURL), fileExtension: sourceURL.pathExtension, for: projectURL)
    }

    public func importRemoteImage(_ sourceURL: URL, for projectURL: URL) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: sourceURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw IconRepositoryError.remoteDownloadFailed
        }
        return try importImageData(data, fileExtension: sourceURL.pathExtension, for: projectURL)
    }

    private func importImageData(_ data: Data, fileExtension: String, for projectURL: URL) throws -> URL {
        let directoryURL = Self.iconDirectoryURL(for: projectURL)
            .appendingPathComponent(Self.imageDirectoryName)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let ext = fileExtension.isEmpty ? "png" : fileExtension.lowercased()
        let destinationURL = directoryURL.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try data.write(to: destinationURL, options: [.atomic])
        return destinationURL
    }

    public static func iconDirectoryURL(for projectURL: URL) -> URL {
        projectURL.appendingPathComponent(iconStoragePath)
    }

    private func loadJSONFiles(in directoryURL: URL) -> [IconData] {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) else {
            return []
        }
        return entries
            .filter { $0.hasSuffix(".json") }
            .compactMap { name in
                let fileURL = directoryURL.appendingPathComponent(name)
                guard let data = try? Data(contentsOf: fileURL),
                      var icon = try? decoder.decode(IconData.self, from: data) else {
                    return nil
                }
                icon.path = fileURL.path
                return icon
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

public enum IconRepositoryError: Error, LocalizedError, Equatable {
    case remoteDownloadFailed

    public var errorDescription: String? {
        switch self {
        case .remoteDownloadFailed: "Unable to download the selected icon."
        }
    }
}
