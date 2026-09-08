import Foundation

// MARK: - Events

/// 协作者数据变化事件。
@MainActor
public enum CollaboratorProvidingEvent {
    /// 协作者新增、更新、删除或整体覆盖保存后触发。
    case collaboratorsChanged
}

// MARK: - Observer Handle

@MainActor
public protocol CollaboratorProvidingObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 协作者管理提供能力协议。
///
/// 负责多条协作者（用户名 + 邮箱）的读取、增删改、默认标记与持久化。
/// 该 Provider 不依赖 Git 操作实现，因此设置、工作区和提交相关插件可以
/// 共享同一份协作者数据，而不需要依赖完整的 `ProviderGit`。
@MainActor
public protocol CollaboratorProviding: AnyObject {
    /// 监听协作者数据变化。回调执行时 `loadCollaborators()` 已可读到最新数据。
    @discardableResult
    func addObserver(
        _ callback: @escaping (CollaboratorProvidingEvent) -> Void
    ) -> any CollaboratorProvidingObserverHandle

    /// 读取全部协作者（按创建时间升序）。
    func loadCollaborators() -> [Collaborator]

    /// 新增协作者；若当前无任何协作者，该条自动成为默认。
    @discardableResult
    func addCollaborator(name: String, email: String) -> Collaborator

    /// 更新已有协作者（按 id 匹配；不存在时为空操作）。
    func updateCollaborator(_ collaborator: Collaborator)

    /// 删除指定协作者。若删除的是默认协作者，剩余第一条自动接任默认。
    func deleteCollaborator(id: UUID)

    /// 查找默认协作者；未显式标记默认时退回第一条（无协作者时为 nil）。
    func findDefault() -> Collaborator?

    /// 将指定协作者设为唯一默认（其余清除默认标记）。
    func setDefault(_ collaborator: Collaborator)

    /// 清除全部协作者的默认标记。
    func clearAllDefaults()

    /// 覆盖保存全部协作者。
    func save(_ collaborators: [Collaborator])
}
