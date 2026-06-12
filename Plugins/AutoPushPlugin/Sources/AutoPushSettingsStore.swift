import Combine
import ProjectSupportKit
import Foundation
import GitOKCoreKit

@MainActor
public final class AutoPushSettingsStore: ObservableObject {
    public static let shared = AutoPushSettingsStore()

    private static let pluginDirName = "AutoPush"
    @Published public private(set) var settings: [String: ProjectBranchAutoPushConfig] = [:]

    public init(settingsFileURL: URL? = nil) {
        self.settingsFileURL = settingsFileURL
        self.settings = AutoPushSettingsPersistence.loadSettings(from: currentStateFileURL())
    }

    private let settingsFileURL: URL?

    public func isAutoPushEnabled(for projectPath: String, branchName: String) -> Bool {
        let key = AutoPushSettingsPersistence.makeKey(projectPath: projectPath, branchName: branchName)
        return settings[key]?.isEnabled == true
    }

    public func setAutoPushEnabled(for projectPath: String, branchName: String, enabled: Bool) {
        update { current in
            AutoPushSettingsPersistence.updatedSettings(
                settings: current,
                projectPath: projectPath,
                branchName: branchName,
                enabled: enabled,
                now: Date()
            )
        }
    }

    public func updateLastPushedDate(for projectPath: String, branchName: String) {
        update { current in
            AutoPushSettingsPersistence.updatedLastPushedDate(
                settings: current,
                projectPath: projectPath,
                branchName: branchName,
                now: Date()
            )
        }
    }

    public func removeConfig(for projectPath: String, branchName: String) {
        update { current in
            AutoPushSettingsPersistence.settingsByRemovingConfig(
                settings: current,
                projectPath: projectPath,
                branchName: branchName
            )
        }
    }

    private func update(_ transform: ([String: ProjectBranchAutoPushConfig]) -> [String: ProjectBranchAutoPushConfig]) {
        let updated = transform(settings)
        settings = updated
        AutoPushSettingsPersistence.persist(updated, to: currentStateFileURL())
    }

    private func currentStateFileURL() -> URL {
        if let settingsFileURL { return settingsFileURL }

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        return appSupport
            .appendingPathComponent("GitOK", isDirectory: true)
            .appendingPathComponent(Self.pluginDirName, isDirectory: true)
            .appendingPathComponent(AutoPushSettingsPersistence.settingsDirName, isDirectory: true)
            .appendingPathComponent(AutoPushSettingsPersistence.stateFileName, isDirectory: false)
    }
}
