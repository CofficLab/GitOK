import Foundation

enum AutoPushSettingsPersistence {
    static let settingsDirName = "settings"
    static let stateFileName = "auto_push_settings.json"
    static let tmpFileName = "auto_push_settings.tmp"

    static func loadSettings(from fileURL: URL, fileManager: FileManager = .default) -> [String: ProjectBranchAutoPushConfig] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode([String: ProjectBranchAutoPushConfig].self, from: data) else {
            return [:]
        }

        return settings
    }

    static func persist(
        _ settings: [String: ProjectBranchAutoPushConfig],
        to fileURL: URL,
        fileManager: FileManager = .default
    ) {
        let settingsDir = fileURL.deletingLastPathComponent()
        let tmpURL = settingsDir.appendingPathComponent(Self.tmpFileName, isDirectory: false)

        try? fileManager.createDirectory(at: settingsDir, withIntermediateDirectories: true, attributes: nil)

        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        do {
            try data.write(to: tmpURL, options: .atomic)

            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try? fileManager.replaceItemAt(fileURL, withItemAt: tmpURL)
            } else {
                try fileManager.moveItem(at: tmpURL, to: fileURL)
            }
        } catch {
            try? fileManager.removeItem(at: tmpURL)
        }
    }

    static func makeKey(projectPath: String, branchName: String) -> String {
        "\(projectPath)://\(branchName)"
    }

    static func parseKey(_ key: String) -> (projectPath: String, branchName: String)? {
        let components = key.components(separatedBy: "://")
        guard components.count == 2 else { return nil }
        return (projectPath: components[0], branchName: components[1])
    }

    static func updatedSettings(
        settings: [String: ProjectBranchAutoPushConfig],
        projectPath: String,
        branchName: String,
        enabled: Bool,
        now: Date
    ) -> [String: ProjectBranchAutoPushConfig] {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        var updated = settings

        if var config = updated[key] {
            config.isEnabled = enabled
            config.lastModified = now
            updated[key] = config
        } else {
            updated[key] = ProjectBranchAutoPushConfig(
                projectPath: projectPath,
                branchName: branchName,
                isEnabled: enabled,
                lastModified: now
            )
        }

        return updated
    }

    static func updatedLastPushedDate(
        settings: [String: ProjectBranchAutoPushConfig],
        projectPath: String,
        branchName: String,
        now: Date
    ) -> [String: ProjectBranchAutoPushConfig] {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        var updated = settings

        if var config = updated[key] {
            config.lastPushedAt = now
            updated[key] = config
        }

        return updated
    }

    static func settingsByRemovingConfig(
        settings: [String: ProjectBranchAutoPushConfig],
        projectPath: String,
        branchName: String
    ) -> [String: ProjectBranchAutoPushConfig] {
        var updated = settings
        updated.removeValue(forKey: makeKey(projectPath: projectPath, branchName: branchName))
        return updated
    }

    static func settingsByRemovingProject(
        settings: [String: ProjectBranchAutoPushConfig],
        projectPath: String
    ) -> [String: ProjectBranchAutoPushConfig] {
        settings.filter { key, _ in
            parseKey(key)?.projectPath != projectPath
        }
    }

    static func configs(forProject projectPath: String, in settings: [String: ProjectBranchAutoPushConfig]) -> [ProjectBranchAutoPushConfig] {
        settings.values.filter { $0.projectPath == projectPath }
    }

    static func enabledConfigs(in settings: [String: ProjectBranchAutoPushConfig]) -> [ProjectBranchAutoPushConfig] {
        settings.values.filter { $0.isEnabled }
    }
}
