import Foundation

// MARK: - Contract

/// Git 用户预设管理提供能力协议。
///
/// 定义「内核 → Git 用户预设」这一段的最小契约：负责多条用户预设
/// （用户名 + 邮箱）的读取、增删改、默认标记与持久化。宿主与插件通过内核
/// 解析 `GitUserPresetProviding` 来读写预设，而不关心具体存储方式
/// （JSON 文件 / SwiftData / 其他）。
///
/// 预设管理规则（与旧版 `GitUserConfigRepo` 对齐）：
/// - 允许保存多条预设；
/// - 至多一条 `isDefault == true`，供「未指定时使用默认」场景；
/// - 首个被添加的预设自动成为默认；
/// - 删除默认预设后，剩余第一条自动接任默认。
///
/// 典型消费方：
/// - `PluginGitUserSettings` 的设置页：列出预设、增删、设为默认、应用到当前项目；
/// - 提交表单：快速切换提交者身份（复用同一份预设数据源）。
///
/// 典型实现：`DefaultGitUserPresetProvider`（JSON 文件持久化，数据落在
/// `StorageProviding.pluginDataDirectory(for:)` 指向的目录）。
@MainActor
public protocol GitUserPresetProviding: AnyObject {
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
