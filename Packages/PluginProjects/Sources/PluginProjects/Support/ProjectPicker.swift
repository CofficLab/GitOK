import AppKit

/// 「添加本地项目」的文件选择流程。
///
/// 侧边栏空态、侧边栏工具栏与根视图引导都提供同一个入口，
/// 行为必须一致：选择目录 → 加入列表 → 立即打开。
enum ProjectPicker {
    /// 弹出目录选择面板；用户确认后依次加入项目列表并打开该目录。
    ///
    /// - Parameter projects: 插件收窄后的项目能力。
    /// - Returns: 用户选择的目录；取消选择时返回 `nil`。
    @discardableResult
    @MainActor
    static func addExistingProject(
        to projects: any ProjectSidebarCapability
    ) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = pluginLocalization.string("Add")
        panel.message = pluginLocalization.string("Choose a repository folder to add to GitOK")
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        projects.addProject(at: url)
        projects.openProject(at: url)
        return url
    }
}
