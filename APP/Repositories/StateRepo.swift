import SwiftUI
import GitOKCoreKit
import GitOKSupportKit
import OSLog


// MARK: - 状态管理Repository协议

protocol StateRepoProtocol {
    var projectPath: String { get set }
    var currentTaskUUID: String { get set }
    var currentTab: String { get set }
    var sidebarVisibility: Bool { get set }
    var globalCommitStyle: CommitStyle { get set }
    var showCommitGraph: Bool { get set }

    func setProjectPath(_ path: String)
    func setCurrentTaskUUID(_ id: String)
    func setCurrentTab(_ tab: String)
    func setSidebarVisibility(_ visible: Bool)
    func setGlobalCommitStyle(_ style: CommitStyle)
    func getCommitStyle(for project: Project?) -> CommitStyle
    func setShowCommitGraph(_ show: Bool)
}

// MARK: - 状态管理Repository实现

class StateRepo: StateRepoProtocol, SuperLog, ObservableObject {
    static let emoji = "📱"

    private let verbose: Bool = false

    // MARK: - App State Properties

    @AppStorage("App.Project")
    var projectPath: String = ""

    @AppStorage("App.CurrentTaskUUID")
    var currentTaskUUID: String = ""

    @AppStorage("App.CurrentTab")
    var currentTab: String = ""

    @AppStorage("App.SidebarVisibility")
    var sidebarVisibility: Bool = true

    @AppStorage("App.CommitStyle")
    var globalCommitStyle: CommitStyle = .lowercase

    @AppStorage("App.ShowCommitGraph")
    var showCommitGraph: Bool = false

    // MARK: - 初始化

    init() {
        if verbose {
            os_log("\(Self.onInit)")
        }
    }

    // MARK: - 状态设置方法

    /**
     * 设置项目路径
     * @param path 项目路径
     */
    func setProjectPath(_ path: String) {
        self.projectPath = path

        if verbose {
            os_log("\(self.t)Project path set to \(path)")
        }
    }

    /**
     * 设置当前任务UUID
     * @param id 任务UUID
     */
    func setCurrentTaskUUID(_ id: String) {
        self.currentTaskUUID = id
        os_log("\(self.t)Current task UUID set to \(id)")
    }

    /**
     * 设置当前标签页
     * @param tab 标签页标识
     */
    func setCurrentTab(_ tab: String) {
        self.currentTab = tab
        os_log("\(self.t)Current tab set to \(tab)")
    }

    /**
     * 设置侧边栏可见性
     * @param visible 是否可见
     */
    func setSidebarVisibility(_ visible: Bool) {
        self.sidebarVisibility = visible
        if verbose {
            os_log("\(self.t)Sidebar visibility set to \(visible)")
        }
    }

    func setGlobalCommitStyle(_ style: CommitStyle) {
        self.globalCommitStyle = style
        if verbose {
            os_log("\(self.t)Global commit style set to \(style.label)")
        }
    }

    func getCommitStyle(for project: Project?) -> CommitStyle {
        // 如果项目有自定义风格，使用项目风格；否则使用全局风格
        if let project = project {
            return project.commitStyle
        }
        return globalCommitStyle
    }

    func setShowCommitGraph(_ show: Bool) {
        self.showCommitGraph = show
        if verbose {
            os_log("\(self.t)Show commit graph set to \(show)")
        }
    }
}
