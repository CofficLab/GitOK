import Foundation

/// Git 用户预设配置（从旧版 `GitUserConfig` 迁移）。
public struct GitUserConfig: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var email: String
    public var isDefault: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}

/// 用户预设的持久化存储（JSON 文件，落在 `StorageProviding.pluginDataDirectory`）。
public final class GitUserConfigStore: @unchecked Sendable {
    private let fileURL: URL

    public init(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("presets.json")
    }

    public func loadPresets() -> [GitUserConfig] {
        guard let data = try? Data(contentsOf: fileURL),
              let presets = try? JSONDecoder().decode([GitUserConfig].self, from: data) else {
            return []
        }
        return presets
    }

    public func addPreset(name: String, email: String) -> GitUserConfig {
        var presets = loadPresets()
        let config = GitUserConfig(
            name: name,
            email: email,
            isDefault: presets.isEmpty
        )
        presets.append(config)
        save(presets)
        return config
    }

    public func deletePreset(id: UUID) {
        var presets = loadPresets()
        presets.removeAll { $0.id == id }
        save(presets)
    }

    public func findDefault() -> GitUserConfig? {
        loadPresets().first { $0.isDefault } ?? loadPresets().first
    }

    public func save(_ presets: [GitUserConfig]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
