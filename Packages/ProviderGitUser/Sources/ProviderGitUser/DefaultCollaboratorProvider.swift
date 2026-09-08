import Foundation

/// `CollaboratorProviding` 的默认实现。
///
/// 基于 JSON 文件的轻量持久化：全部协作者保存在指定目录下的 `collaborators.json`。
/// 目录不存在时自动创建。线程安全由 `@MainActor` 保证。
@MainActor
public final class DefaultCollaboratorProvider: CollaboratorProviding {
    private let fileURL: URL
    private var observers: [(id: UUID, callback: (CollaboratorProvidingEvent) -> Void)] = []

    /// - Parameter directory: 协作者数据所在目录；不存在会自动创建。
    public init(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("collaborators.json")
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
        _ callback: @escaping (CollaboratorProvidingEvent) -> Void
    ) -> any CollaboratorProvidingObserverHandle {
        let id = UUID()
        observers.append((id: id, callback: callback))
        return ObserverHandle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    public func loadCollaborators() -> [Collaborator] {
        guard let data = try? Data(contentsOf: fileURL),
              let collaborators = try? JSONDecoder().decode([Collaborator].self, from: data) else {
            return []
        }
        return collaborators
    }

    @discardableResult
    public func addCollaborator(name: String, email: String) -> Collaborator {
        var collaborators = loadCollaborators()
        let collaborator = Collaborator(
            name: name,
            email: email,
            isDefault: collaborators.isEmpty
        )
        collaborators.append(collaborator)
        save(collaborators)
        return collaborator
    }

    public func updateCollaborator(_ collaborator: Collaborator) {
        var collaborators = loadCollaborators()
        guard let index = collaborators.firstIndex(where: { $0.id == collaborator.id }) else { return }
        collaborators[index] = collaborator
        save(collaborators)
    }

    public func deleteCollaborator(id: UUID) {
        var collaborators = loadCollaborators()
        let removed = collaborators.first { $0.id == id }
        collaborators.removeAll { $0.id == id }
        if removed?.isDefault == true, var first = collaborators.first, !first.isDefault {
            first.isDefault = true
            collaborators[0] = first
        }
        save(collaborators)
    }

    public func findDefault() -> Collaborator? {
        let collaborators = loadCollaborators()
        return collaborators.first { $0.isDefault } ?? collaborators.first
    }

    public func setDefault(_ collaborator: Collaborator) {
        var collaborators = loadCollaborators()
        collaborators = collaborators.map { candidate in
            var updated = candidate
            updated.isDefault = candidate.id == collaborator.id
            return updated
        }
        save(collaborators)
    }

    public func clearAllDefaults() {
        var collaborators = loadCollaborators()
        collaborators = collaborators.map { collaborator in
            var updated = collaborator
            updated.isDefault = false
            return updated
        }
        save(collaborators)
    }

    public func save(_ collaborators: [Collaborator]) {
        guard let data = try? JSONEncoder().encode(collaborators),
              (try? data.write(to: fileURL, options: .atomic)) != nil else { return }
        let currentObservers = observers
        for observer in currentObservers {
            observer.callback(.collaboratorsChanged)
        }
    }

    private final class ObserverHandle: CollaboratorProvidingObserverHandle {
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
