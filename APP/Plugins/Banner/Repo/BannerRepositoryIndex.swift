import Foundation

enum BannerRepositoryIndex {
    static func jsonFileURLs(
        in directoryURL: URL,
        fileManager: FileManager = .default
    ) -> [URL] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let files = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) else {
            return []
        }

        return files
            .filter { $0.hasSuffix(".json") }
            .map { directoryURL.appendingPathComponent($0) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    static func loadModels<Model>(
        from directoryURL: URL,
        fileManager: FileManager = .default,
        load: (URL) -> Model?,
        sort: (Model, Model) -> Bool
    ) -> [Model] {
        jsonFileURLs(in: directoryURL, fileManager: fileManager)
            .compactMap(load)
            .sorted(by: sort)
    }
}
