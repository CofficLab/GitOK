import Foundation

/// `CoAuthorProviding` 的默认实现。
///
/// 基于 JSON 文件的轻量持久化：全部协作者保存在指定目录下的 `authors.json`。
/// 目录不存在时自动创建。线程安全由 `@MainActor` 保证。
@MainActor
public final class DefaultCoAuthorProvider: CoAuthorProviding {
    private let fileURL: URL
    private var observers: [(id: UUID, callback: (CoAuthorProvidingEvent) -> Void)] = []

    /// - Parameter directory: 协作者数据所在目录；不存在会自动创建。
    public init(directory: URL) {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.fileURL = directory.appendingPathComponent("authors.json")
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
        _ callback: @escaping (CoAuthorProvidingEvent) -> Void
    ) -> any CoAuthorProvidingObserverHandle {
        let id = UUID()
        observers.append((id: id, callback: callback))
        return ObserverHandle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    public func loadAuthors() -> [CoAuthor] {
        guard let data = try? Data(contentsOf: fileURL),
              let authors = try? JSONDecoder().decode([CoAuthor].self, from: data) else {
            return []
        }
        return authors
    }

    @discardableResult
    public func addAuthor(name: String, email: String) -> CoAuthor? {
        var authors = loadAuthors()
        // 若 email 已存在则不重复添加
        guard !authors.contains(where: { $0.email == email }) else {
            return nil
        }
        let author = CoAuthor(name: name, email: email)
        authors.append(author)
        save(authors)
        return author
    }

    public func updateAuthor(_ author: CoAuthor) {
        var authors = loadAuthors()
        guard let index = authors.firstIndex(where: { $0.id == author.id }) else { return }
        authors[index] = author
        save(authors)
    }

    public func deleteAuthor(id: UUID) {
        var authors = loadAuthors()
        authors.removeAll { $0.id == id }
        save(authors)
    }

    public func save(_ authors: [CoAuthor]) {
        guard let data = try? JSONEncoder().encode(authors),
              (try? data.write(to: fileURL, options: .atomic)) != nil else { return }
        let currentObservers = observers
        for observer in currentObservers {
            observer.callback(.authorsChanged)
        }
    }

    private final class ObserverHandle: CoAuthorProvidingObserverHandle {
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
