import Foundation
import KitGit
import ProviderCoAuthor
import ProviderGit
import ProviderStorage

// MARK: - Events

/// 提交表单状态事件。
@MainActor
public enum CommitFormEvent {
    /// 表单状态（subject / category / style / coAuthors）变化。
    case stateChanged

    /// 一次提交成功完成（含提交并推送）。消费方（commit 列表 / 工作区状态 / diff）据此刷新。
    case committed

    /// 提交过程失败。
    case submitFailed(Error)
}

// MARK: - Observer Handle

@MainActor
public protocol CommitFormObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 提交表单提供能力协议
///
/// 维护「当前项目提交表单」的状态（subject / category / style / coAuthors），
/// 并负责执行提交动作（add -A → commit → push）。状态变化通过**观察者体系**
/// 通知（参考 Lumi 其他 Provider），消费方调用 `addObserver` 订阅事件。
///
/// 协议只声明状态与动作，不关心 UI——视图由 PluginCommitForm 提供。
@MainActor
public protocol CommitFormProviding: AnyObject {
    /// 提交信息 subject（不含类别前缀）。
    var subject: String { get }

    /// 当前提交类别。
    var category: CommitCategory { get }

    /// 当前生效的提交风格。跟随 `loadStyle(for:)` 选择的项目切换。
    var style: CommitStyle { get }

    /// 当前选中的共同作者。
    var coAuthors: [CoAuthor] { get }

    /// 是否正在提交（提交中禁用按钮）。
    var isSubmitting: Bool { get }

    /// 上次提交失败的错误描述（UI 展示用）。
    var lastErrorMessage: String? { get }

    /// 监听表单事件。
    @discardableResult
    func addObserver(_ callback: @escaping (CommitFormEvent) -> Void) -> any CommitFormObserverHandle

    /// 更新 subject。
    func setSubject(_ subject: String)

    /// 更新类别（自动重置 subject 为默认信息，对齐旧版交互）。
    func setCategory(_ category: CommitCategory)

    /// 更新**当前项目**的风格（无当前项目时仅更新内存状态）。
    ///
    /// 风格按项目持久化，因此这是「用户在表单里换风格」的入口：
    /// 写入当前已加载的项目；尚未选择项目时只影响内存。
    func setStyle(_ style: CommitStyle)

    /// 读取指定项目的提交风格；该项目无记录时回退全局默认风格。
    func style(for projectURL: URL) -> CommitStyle

    /// 写入指定项目的提交风格并持久化。
    func setStyle(_ style: CommitStyle, for projectURL: URL)

    /// 切换当前项目：加载该项目的风格，并把它记为后续 `setStyle(_:)` 的写入目标。
    ///
    /// 传 `nil` 表示没有当前项目，风格回退全局默认值。
    /// 只同步风格，不改动 subject（不打断用户已输入的提交信息）。
    func loadStyle(for projectURL: URL?)

    /// 更新共同作者。
    func setCoAuthors(_ coAuthors: [CoAuthor])

    /// 执行提交。
    ///
    /// `commitOnly = true` 只提交不推送；`false` 提交并推送。
    /// 流程：`git add -A` → `git commit -m <message>` → （可选）`git push`。
    /// 成功后广播 `committed` 并重置 subject。
    func submit(commitOnly: Bool, in repository: URL) async throws
}

// MARK: - Default Implementation

/// 默认实现：内存状态 + 弱引用观察者广播。
///
/// 状态保持单一权威来源；广播在状态更新完成后同步执行。
/// 观察者令牌被外部释放后自动失效，并在下次广播时清理。
@MainActor
public final class DefaultCommitFormProvider: CommitFormProviding {
    public private(set) var subject: String
    public private(set) var category: CommitCategory
    public private(set) var style: CommitStyle
    public private(set) var coAuthors: [CoAuthor]
    public private(set) var isSubmitting = false
    public private(set) var lastErrorMessage: String?

    /// 活动上报器（可选）：提交 / 推送进行中向状态栏等活动消费方报告阶段。
    ///
    /// 通过闭包解耦（不依赖具体 Activity 包）；调用方在 Factory 装配时注入。
    public var activityReporter: (@MainActor (String?) -> Void)?
    private let git: (any GitProviding)?

    /// 按项目持久化的风格存储。
    private let styleStore: CommitStylePerProjectStore

    /// 当前已加载风格的项目；`setStyle(_:)` 写入它的记录。
    private var loadedProjectURL: URL?

    private var observers: [WeakCommitFormObserver] = []

    /// - Parameter storage: 存储能力；传 `nil` 时风格退化为纯内存（测试 / 预览）。
    public init(
        subject: String = "",
        category: CommitCategory = .Chore,
        style: CommitStyle = .emoji,
        coAuthors: [CoAuthor] = [],
        git: (any GitProviding)? = nil,
        storage: (any StorageProviding)? = nil
    ) {
        self.subject = subject
        self.category = category
        self.style = style
        self.coAuthors = coAuthors
        self.git = git
        self.styleStore = CommitStylePerProjectStore(
            directory: storage?.pluginDataDirectory(for: "com.coffic.gitok.plugin.commit-form")
        )
    }

    public func setSubject(_ newSubject: String) {
        guard subject != newSubject else { return }
        subject = newSubject
        notifyObservers(.stateChanged)
    }

    public func setCategory(_ newCategory: CommitCategory) {
        guard category != newCategory else { return }
        category = newCategory
        // 对齐旧版：切换类别后重置 subject 为默认信息。
        subject = CommitMessageRules.subjectAfterCategoryChange(category: newCategory, style: style)
        notifyObservers(.stateChanged)
    }

    /// 更新当前项目的风格；尚未选择项目时只更新内存状态。
    public func setStyle(_ newStyle: CommitStyle) {
        guard style != newStyle else { return }
        style = newStyle
        // 对齐旧版：切换风格后重置 subject 为默认信息。
        subject = CommitMessageRules.subjectAfterStyleChange(category: category, style: newStyle)
        // 写入当前项目的记录，使该项目的选择在下次切换回来时保持。
        if let loadedProjectURL {
            styleStore.setStyle(newStyle, for: loadedProjectURL)
        }
        notifyObservers(.stateChanged)
    }

    public func style(for projectURL: URL) -> CommitStyle {
        styleStore.style(for: projectURL) ?? CommitStyleStore.current
    }

    public func setStyle(_ newStyle: CommitStyle, for projectURL: URL) {
        styleStore.setStyle(newStyle, for: projectURL)
        // 正在展示该项目时同步内存状态，避免 UI 与落盘值不一致。
        guard isCurrentProject(projectURL) else { return }
        loadedProjectURL = projectURL
        applyLoadedStyle(newStyle)
    }

    public func loadStyle(for projectURL: URL?) {
        loadedProjectURL = projectURL
        guard let projectURL else {
            // 没有当前项目：回退全局默认风格。
            applyLoadedStyle(CommitStyleStore.current)
            return
        }
        applyLoadedStyle(style(for: projectURL))
    }

    /// 同步当前风格到 `newStyle`，并重置 subject 为对应的默认信息。
    ///
    /// 切换项目时 subject 本就该按新项目的风格重置；`setStyle(_:for:)` 复用
    /// 同一路径，保证两条入口的行为一致。
    private func applyLoadedStyle(_ newStyle: CommitStyle) {
        guard style != newStyle else { return }
        style = newStyle
        subject = CommitMessageRules.subjectAfterStyleChange(category: category, style: newStyle)
        notifyObservers(.stateChanged)
    }

    /// 判断给定 URL 是否为当前已加载风格的项目。
    private func isCurrentProject(_ projectURL: URL) -> Bool {
        guard let loadedProjectURL else { return false }
        return loadedProjectURL.standardizedFileURL == projectURL.standardizedFileURL
    }

    public func setCoAuthors(_ newCoAuthors: [CoAuthor]) {
        guard coAuthors != newCoAuthors else { return }
        coAuthors = newCoAuthors
        notifyObservers(.stateChanged)
    }

    public func submit(commitOnly: Bool, in repository: URL) async throws {
        guard !isSubmitting else { return }
        isSubmitting = true
        lastErrorMessage = nil
        notifyObservers(.stateChanged)

        do {
            let plan = CommitMessageRules.submitPlan(
                message: CommitMessageRules.formattedMessage(
                    subject: subject,
                    category: category,
                    style: style,
                    coAuthors: coAuthors
                ),
                commitOnly: commitOnly
            )

            activityReporter?(LumiPluginLocalization.string("Committing...", bundle: .module))
            guard let git else {
                throw GitProviderError.noBackendAvailable
            }
            try git.addAll(in: repository)
            _ = try git.commit(message: plan.message, in: repository)
            if plan.pushesAfterCommit {
                activityReporter?(LumiPluginLocalization.string("Synchronizing...", bundle: .module))
                let trackingStatus = git.remoteTrackingStatus(in: repository)
                if trackingStatus.hasUpstream {
                    _ = try git.synchronize(in: repository)
                } else {
                    // 新分支尚未配置 upstream，仍使用普通 push 触发发布分支流程。
                    _ = try git.push(in: repository)
                }
            }
            activityReporter?(nil)

            isSubmitting = false
            // 提交成功后重置 subject 为默认信息（对齐旧版 onProjectDidCommit）。
            subject = CommitMessageRules.subjectAfterCategoryChange(category: category, style: style)
            notifyObservers(.stateChanged)
            notifyObservers(.committed)
        } catch {
            activityReporter?(nil)
            isSubmitting = false
            lastErrorMessage = error.localizedDescription
            notifyObservers(.stateChanged)
            notifyObservers(.submitFailed(error))
            throw error
        }
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (CommitFormEvent) -> Void
    ) -> any CommitFormObserverHandle {
        let handle = CommitFormObserverHandleImpl(owner: self, callback: callback)
        observers.append(WeakCommitFormObserver(handle))
        return handle
    }

    fileprivate func removeObserver(_ handle: any CommitFormObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    private func notifyObservers(_ event: CommitFormEvent) {
        observers.removeAll { $0.handle == nil }
        let current = observers
        for observer in current {
            observer.handle?.invoke(event)
        }
    }
}

// MARK: - Observer Handle Implementation

@MainActor
private final class CommitFormObserverHandleImpl: CommitFormObserverHandle {
    private weak var owner: DefaultCommitFormProvider?
    private let callback: (CommitFormEvent) -> Void
    private var isCancelled = false

    init(owner: DefaultCommitFormProvider, callback: @escaping (CommitFormEvent) -> Void) {
        self.owner = owner
        self.callback = callback
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        owner?.removeObserver(self)
    }

    fileprivate func invoke(_ event: CommitFormEvent) {
        guard !isCancelled else { return }
        callback(event)
    }
}

@MainActor
private final class WeakCommitFormObserver {
    fileprivate weak var handle: CommitFormObserverHandleImpl?

    init(_ handle: CommitFormObserverHandleImpl) {
        self.handle = handle
    }
}
