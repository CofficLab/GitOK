import Foundation

// MARK: - Events

/// 协作者数据变化事件。
@MainActor
public enum CoAuthorProvidingEvent {
    /// 协作者新增、更新、删除或整体覆盖保存后触发。
    case authorsChanged
}

// MARK: - Observer Handle

@MainActor
public protocol CoAuthorProvidingObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 协作者管理提供能力协议。
///
/// 负责多条协作者（用户名 + 邮箱）的读取、增删改与持久化。
/// 该 Provider 不依赖 Git 操作实现，因此提交表单和其他插件可以
/// 共享同一份协作者数据，而不需要依赖完整的 `ProviderGit`。
@MainActor
public protocol CoAuthorProviding: AnyObject {
    /// 监听协作者数据变化。回调执行时 `loadAuthors()` 已可读到最新数据。
    @discardableResult
    func addObserver(
        _ callback: @escaping (CoAuthorProvidingEvent) -> Void
    ) -> any CoAuthorProvidingObserverHandle

    /// 读取全部协作者（按创建时间升序）。
    func loadAuthors() -> [CoAuthor]

    /// 新增协作者；若 email 已存在则不重复添加。
    @discardableResult
    func addAuthor(name: String, email: String) -> CoAuthor?

    /// 更新已有协作者（按 id 匹配；不存在时为空操作）。
    func updateAuthor(_ author: CoAuthor)

    /// 删除指定协作者。
    func deleteAuthor(id: UUID)

    /// 覆盖保存全部协作者。
    func save(_ authors: [CoAuthor])
}
