import SwiftUI
import GitOKCoreKit
import GitOKSupportKit
import OSLog


// MARK: - 状态管理Repository协议

public protocol StateRepoProtocol {
    var projectPath: String { get set }
    var currentTaskUUID: String { get set }
    var currentTab: GitOKAppTab { get set }
    var sidebarVisibility: Bool { get set }
    var globalCommitStyle: CommitStyle { get set }
    var showCommitGraph: Bool { get set }

    func setProjectPath(_ path: String)
    func setCurrentTaskUUID(_ id: String)
    func setCurrentTab(_ tab: GitOKAppTab)
    func setSidebarVisibility(_ visible: Bool)
    func setGlobalCommitStyle(_ style: CommitStyle)
    func getCommitStyle(for project: Project?) -> CommitStyle
    func setShowCommitGraph(_ show: Bool)
}

// MARK: - 状态管理Repository实现

public class StateRepo: StateRepoProtocol, SuperLog, ObservableObject {
    public static let emoji = "📱"
    public nonisolated static let verbose = false

    // MARK: - App State Properties

    @AppStorage("App.Project")
    public var projectPath: String = ""

    @AppStorage("App.CurrentTaskUUID")
    public var currentTaskUUID: String = ""

    @AppStorage("App.CurrentTab")
    private var currentTabRawValue: String = GitOKAppTab.git.rawValue

    public var currentTab: GitOKAppTab {
        get { GitOKAppTab.migrated(from: currentTabRawValue) ?? .git }
        set { currentTabRawValue = newValue.rawValue }
    }

    @AppStorage("App.SidebarVisibility")
    public var sidebarVisibility: Bool = true

    @AppStorage("App.CommitStyle")
    public var globalCommitStyle: CommitStyle = .lowercase

    @AppStorage("App.ShowCommitGraph")
    public var showCommitGraph: Bool = false

    // MARK: - 初始化

    public init() {
        if Self.verbose {
            os_log("\(Self.onInit)")
        }
    }

    // MARK: - 状态设置方法

    /**
     * 设置项目路径
     * @param path 项目路径
     */
    public func setProjectPath(_ path: String) {
        self.projectPath = path

        if Self.verbose {
            os_log("\(self.t)Project path set to \(path)")
        }
    }

    /**
     * 设置当前任务UUID
     * @param id 任务UUID
     */
    public func setCurrentTaskUUID(_ id: String) {
        self.currentTaskUUID = id
        if Self.verbose {
            os_log("\(self.t)Current task UUID set to \(id)")
        }
    }

    /**
     * 设置当前标签页
     * @param tab 标签页标识
     */
    public func setCurrentTab(_ tab: GitOKAppTab) {
        self.currentTab = tab
        if Self.verbose {
            os_log("\(self.t)Current tab set to \(tab.rawValue)")
        }
    }

    /**
     * 设置侧边栏可见性
     * @param visible 是否可见
     */
    public func setSidebarVisibility(_ visible: Bool) {
        self.sidebarVisibility = visible
        if Self.verbose {
            os_log("\(self.t)Sidebar visibility set to \(visible)")
        }
    }

    public func setGlobalCommitStyle(_ style: CommitStyle) {
        self.globalCommitStyle = style
        if Self.verbose {
            os_log("\(self.t)Global commit style set to \(style.label)")
        }
    }

    public func getCommitStyle(for project: Project?) -> CommitStyle {
        // 如果项目有自定义风格，使用项目风格；否则使用全局风格
        if let project = project {
            return project.commitStyle
        }
        return globalCommitStyle
    }

    public func setShowCommitGraph(_ show: Bool) {
        self.showCommitGraph = show
        if Self.verbose {
            os_log("\(self.t)Show commit graph set to \(show)")
        }
    }
}
