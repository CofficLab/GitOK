import Foundation

public enum FileInfoPathPresentation {
    public static func components(for filePath: String) -> [String] {
        filePath
            .split(separator: "/")
            .map(String.init)
            .filter { $0.isEmpty == false }
    }

    public static func displayComponents(for filePath: String) -> [String] {
        let components = components(for: filePath)
        return components.isEmpty ? [filePath] : components
    }

    public static func targetURL(projectPath: String?, filePath: String?) -> URL? {
        guard let filePath, filePath.isEmpty == false else { return nil }
        if filePath.hasPrefix("/") {
            return URL(fileURLWithPath: filePath).standardizedFileURL
        }

        guard let projectPath, projectPath.isEmpty == false else { return nil }
        return URL(fileURLWithPath: projectPath)
            .appendingPathComponent(filePath)
            .standardizedFileURL
    }
}
