import Foundation
import KitGit

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

    /// 当前提交风格。
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

    /// 更新风格（自动重置 subject 为默认信息，对齐旧版交互）。
    func setStyle(_ style: CommitStyle)

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

    private var observers: [WeakCommitFormObserver] = []

    public init(
        subject: String = "",
        category: CommitCategory = .Chore,
        style: CommitStyle = .emoji,
        coAuthors: [CoAuthor] = []
    ) {
        self.subject = subject
        self.category = category
        self.style = style
        self.coAuthors = coAuthors
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

    public func setStyle(_ newStyle: CommitStyle) {
        guard style != newStyle else { return }
        style = newStyle
        // 对齐旧版：切换风格后重置 subject 为默认信息。
        subject = CommitMessageRules.subjectAfterStyleChange(category: category, style: newStyle)
        notifyObservers(.stateChanged)
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

            try GitCommitOperation.addAll(in: repository)
            try GitCommitOperation.commit(message: plan.message, in: repository)
            if plan.pushesAfterCommit {
                try GitCommitOperation.push(in: repository)
            }

            isSubmitting = false
            // 提交成功后重置 subject 为默认信息（对齐旧版 onProjectDidCommit）。
            subject = CommitMessageRules.subjectAfterCategoryChange(category: category, style: style)
            notifyObservers(.stateChanged)
            notifyObservers(.committed)
        } catch {
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
