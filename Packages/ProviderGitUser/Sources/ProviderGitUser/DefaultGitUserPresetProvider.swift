import Foundation

/// `GitUserPresetProviding` 的默认实现。
///
/// 基于 JSON 文件的轻量持久化：全部预设保存在指定目录下的 `presets.json`。
/// 目录不存在时自动创建。线程安全由 `@MainActor` 保证。
@MainActor
public final class DefaultGitUserPresetProvider: GitUserPresetProviding {
    private let fileURL: URL
    private var observers: [(id: UUID, callback: (GitUserPresetProvidingEvent) -> Void)] = []

    /// - Parameter directory: 预设数据所在目录；不存在会自动创建。
    public init(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("presets.json")
    }

    /// 精确指定数据文件位置（便于测试）。
    public init(fileURL: URL) {
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = fileURL
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (GitUserPresetProvidingEvent) -> Void
    ) -> any GitUserPresetProvidingObserverHandle {
        let id = UUID()
        observers.append((id: id, callback: callback))
        return ObserverHandle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    public func loadPresets() -> [GitUserPreset] {
        guard let data = try? Data(contentsOf: fileURL),
              let presets = try? JSONDecoder().decode([GitUserPreset].self, from: data) else {
            return []
        }
        return presets
    }

    @discardableResult
    public func addPreset(name: String, email: String) -> GitUserPreset {
        var presets = loadPresets()
        let preset = GitUserPreset(
            name: name,
            email: email,
            isDefault: presets.isEmpty
        )
        presets.append(preset)
        save(presets)
        return preset
    }

    public func updatePreset(_ preset: GitUserPreset) {
        var presets = loadPresets()
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index] = preset
        save(presets)
    }

    public func deletePreset(id: UUID) {
        var presets = loadPresets()
        let removed = presets.first { $0.id == id }
        presets.removeAll { $0.id == id }
        if removed?.isDefault == true, var first = presets.first, !first.isDefault {
            first.isDefault = true
            presets[0] = first
        }
        save(presets)
    }

    public func findDefault() -> GitUserPreset? {
        let presets = loadPresets()
        return presets.first { $0.isDefault } ?? presets.first
    }

    public func setDefault(_ preset: GitUserPreset) {
        var presets = loadPresets()
        presets = presets.map { candidate in
            var updated = candidate
            updated.isDefault = candidate.id == preset.id
            return updated
        }
        save(presets)
    }

    public func clearAllDefaults() {
        var presets = loadPresets()
        presets = presets.map { preset in
            var updated = preset
            updated.isDefault = false
            return updated
        }
        save(presets)
    }

    public func save(_ presets: [GitUserPreset]) {
        guard let data = try? JSONEncoder().encode(presets),
              (try? data.write(to: fileURL, options: .atomic)) != nil else { return }
        let currentObservers = observers
        for observer in currentObservers {
            observer.callback(.presetsChanged)
        }
    }

    private final class ObserverHandle: GitUserPresetProvidingObserverHandle {
        private let onCancel: () -> Void
        private var isCancelled = false

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() {
            guard !isCancelled else { return }
            isCancelled = true
            onCancel()
        }
    }
}
