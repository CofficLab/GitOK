import Combine
import Foundation

/// Stores user-controlled plugin enablement.
@MainActor
public final class PluginSettingsStore: ObservableObject {
    public static let shared = PluginSettingsStore()

    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    @Published public private(set) var settings: [String: Bool] = [:]

    init(
        userDefaults: UserDefaults = .standard,
        userDefaultsKey: String = "GitOK_PluginSettings"
    ) {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        settings = loadSettings()
    }

    public func isPluginEnabled(_ pluginId: String, defaultEnabled: Bool = true) -> Bool {
        settings[pluginId] ?? defaultEnabled
    }

    public func hasUserConfigured(_ pluginId: String) -> Bool {
        settings[pluginId] != nil
    }

    public func setPluginEnabled(_ pluginId: String, enabled: Bool) {
        settings[pluginId] = enabled
        saveSettings()
    }

    private func loadSettings() -> [String: Bool] {
        userDefaults.object(forKey: userDefaultsKey) as? [String: Bool] ?? [:]
    }

    private func saveSettings() {
        userDefaults.set(settings, forKey: userDefaultsKey)
    }
}

public struct PluginInfo: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let defaultEnabled: Bool
    public let allowUserToggle: Bool
    public let isDeveloperEnabled: () -> Bool

    public init(
        id: String,
        name: String,
        description: String,
        icon: String = "puzzlepiece.extension",
        defaultEnabled: Bool = true,
        allowUserToggle: Bool = true,
        isDeveloperEnabled: @escaping () -> Bool = { true }
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.defaultEnabled = defaultEnabled
        self.allowUserToggle = allowUserToggle
        self.isDeveloperEnabled = isDeveloperEnabled
    }
}
