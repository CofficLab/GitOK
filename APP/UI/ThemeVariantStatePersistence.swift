import Foundation

enum ThemeVariantStatePersistence {
    static func loadString(forKey key: String, fileURL: URL, fileManager: FileManager = .default) -> String? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return nil
        }
        return dict[key] as? String
    }

    static func saveString(
        _ value: String,
        forKey key: String,
        fileURL: URL,
        settingsDirURL: URL,
        tmpFileName: String,
        fileManager: FileManager = .default
    ) {
        var dict: [String: Any] = [:]

        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let existing = plist as? [String: Any] {
            dict = existing
        }

        dict[key] = value

        guard let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) else {
            return
        }

        do {
            try fileManager.createDirectory(at: settingsDirURL, withIntermediateDirectories: true, attributes: nil)

            let tmpURL = settingsDirURL.appendingPathComponent(tmpFileName, isDirectory: false)
            try data.write(to: tmpURL, options: .atomic)

            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try? fileManager.replaceItemAt(fileURL, withItemAt: tmpURL)
            } else {
                try fileManager.moveItem(at: tmpURL, to: fileURL)
            }
        } catch {
            // Debug UI persistence failures should remain non-fatal.
        }
    }
}
