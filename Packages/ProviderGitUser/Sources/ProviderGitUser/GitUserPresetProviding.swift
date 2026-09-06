import Foundation

// MARK: - Events

/// Git 用户预设数据变化事件。
@MainActor
public enum GitUserPresetProvidingEvent {
    /// 预设新增、更新、删除或整体覆盖保存后触发。
    case presetsChanged
}

// MARK: - Observer Handle

@MainActor
public protocol GitUserPresetProvidingObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// Git 用户预设管理提供能力协议。
///
/// 负责多条用户预设（用户名 + 邮箱）的读取、增删改、默认标记与持久化。
/// 该 Provider 不依赖 Git 操作实现，因此设置、工作区和提交相关插件可以
/// 共享同一份用户身份数据，而不需要依赖完整的 `ProviderGit`。
@MainActor
public protocol GitUserPresetProviding: AnyObject {
    /// 监听预设数据变化。回调执行时 `loadPresets()` 已可读到最新数据。
    @discardableResult
    func addObserver(
        _ callback: @escaping (GitUserPresetProvidingEvent) -> Void
    ) -> any GitUserPresetProvidingObserverHandle

    /// 读取全部预设（按创建时间升序）。
    func loadPresets() -> [GitUserPreset]

    /// 新增预设；若当前无任何预设，该条自动成为默认。
    @discardableResult
    func addPreset(name: String, email: String) -> GitUserPreset

    /// 更新已有预设（按 id 匹配；不存在时为空操作）。
    func updatePreset(_ preset: GitUserPreset)

    /// 删除指定预设。若删除的是默认预设，剩余第一条自动接任默认。
    func deletePreset(id: UUID)

    /// 查找默认预设；未显式标记默认时退回第一条（无预设时为 nil）。
    func findDefault() -> GitUserPreset?

    /// 将指定预设设为唯一默认（其余清除默认标记）。
    func setDefault(_ preset: GitUserPreset)

    /// 清除全部预设的默认标记。
    func clearAllDefaults()

    /// 覆盖保存全部预设。
    func save(_ presets: [GitUserPreset])
}
