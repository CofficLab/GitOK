import Foundation

/// 神秘主题变体的自包含状态存储。
enum ThemeVariantStateStore {
    private static let pluginDirName = "Themes"
    private static let settingsFileName = "theme_state.plist"
    private static let tmpFileName = "theme_state.tmp"

    private static let settingsDirURL: URL = {
        AppConfig.getDBFolderURL()
            .appendingPathComponent("Core", isDirectory: true)
            .appendingPathComponent(pluginDirName, isDirectory: true)
            .appendingPathComponent("settings", isDirectory: true)
    }()

    private static func settingsFileURL() -> URL {
        settingsDirURL.appendingPathComponent(settingsFileName, isDirectory: false)
    }

    static func loadString(forKey key: String) -> String? {
        ThemeVariantStatePersistence.loadString(
            forKey: key,
            fileURL: settingsFileURL()
        )
    }

    static func saveString(_ value: String, forKey key: String) {
        ThemeVariantStatePersistence.saveString(
            value,
            forKey: key,
            fileURL: settingsFileURL(),
            settingsDirURL: settingsDirURL,
            tmpFileName: tmpFileName
        )
    }
}
