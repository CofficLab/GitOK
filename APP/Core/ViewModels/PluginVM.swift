import Foundation
import MagicKit
import ObjectiveC.runtime
import OSLog
import StoreKit
import SwiftData
import SwiftUI
import Combine
import GitOKPluginKit
import GitOKUI
import PluginActivityStatus
import PluginAutoPush
import PluginBanner
import PluginBannerTab
import PluginBranch
import PluginCleanStatus
import PluginCommit
import PluginConflictResolver
import PluginFileInfo
import PluginGitIgnore
import PluginGitDetail
import PluginGitLFS
import PluginGitPull
import PluginGitPush
import PluginGitSync
import PluginGitTab
import PluginGitWatcher
import PluginIcon
import PluginIconTab
import PluginLicense
import PluginOpenAntigravity
import PluginOpenGitHubDesktop
import PluginOpenCursor
import PluginOpenFinder
import PluginOpenKiro
import PluginOpenRemote
import PluginOpenTerminal
import PluginOpenTrae
import PluginOpenVSCode
import PluginOpenXcode
import PluginProjectPicker
import PluginReadme
import PluginRemoteRepository
import PluginSettingsButton
import PluginSmartMerge
import PluginStash
import PluginSubmodule
import PluginThemeAurora
import PluginThemeDracula
import PluginThemeEmber
import PluginThemeGitOK
import PluginThemeGraphite
import PluginThemeHarbor
import PluginThemeGitHubLight
import PluginThemeGlacier
import PluginThemeMatrix
import PluginThemeMidnight
import PluginThemeMountain
import PluginThemeNebula
import PluginThemeOneDark
import PluginThemeOrchard
import PluginThemeRiver
import PluginThemeSpring
import PluginThemeStatusBar
import PluginThemeSummer
import PluginThemeWinter
import PluginThemeXcodeLight
import PluginUnpushedStatus

class PluginVM: ObservableObject, SuperLog, SuperThread {
    nonisolated static let emoji = "🧩"
    static let verbose = false

    /// 是否注册所有插件（开发调试用，设为 false 可禁用所有插件）
    static var registerAllPlugins: Bool = true

    @Published private(set) var plugins: [SuperPlugin] = []

    /// 插件设置存储
    private let settingsStore = PluginSettingsStore.shared

    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Plugin Registration

    /// 已注册的插件实例列表
    private var registeredPlugins: [any SuperPlugin] = []

    /// 已使用的插件标签集合（用于检测重复）
    private var usedLabels: Set<String> = []

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    private func register(_ plugin: any SuperPlugin) {
        let label = plugin.instanceLabel

        // 检查标签是否已存在
        if usedLabels.contains(label) {
            let pluginType = String(describing: type(of: plugin))
            os_log(.error, "\(Self.t)❌ Duplicate plugin label '\(label)' in \(pluginType)")
            assertionFailure("Duplicate plugin label: \(label)")
            return
        }

        // 标记该标签已使用
        usedLabels.insert(label)
        registeredPlugins.append(plugin)
    }

    /// 获取所有已注册的插件实例，按 order 排序
    /// - Returns: 排序后的插件实例数组
    private func getAllPlugins() -> [any SuperPlugin] {
        registeredPlugins.sorted { $0.pluginOrder < $1.pluginOrder }
    }

    /// 清空所有注册的插件
    private func clearRegisteredPlugins() {
        registeredPlugins.removeAll()
        usedLabels.removeAll()
    }

    /// 已注册插件数量
    private var registeredCount: Int {
        registeredPlugins.count
    }

    /// 自动发现并注册所有插件
    /// 通过扫描 Objective-C runtime 中所有以 "Plugin" 结尾的类
    private func autoDiscoverAndRegisterPlugins() {
        let start = Date()
        os_log("\(self.t)🚀 Startup begin: autoDiscoverAndRegisterPlugins")

        // 检查是否禁用所有插件注册
        if !Self.registerAllPlugins {
            os_log("\(self.t)⚠️ Plugin registration is disabled via registerAllPlugins=false")
            return
        }

        // 清空已有注册（防止重复注册）
        clearRegisteredPlugins()

        var count: UInt32 = 0
        guard let classList = objc_copyClassList(&count) else {
            os_log(.error, "\(self.t)❌ Failed to get class list")
            return
        }
        defer { free(UnsafeMutableRawPointer(classList)) }

        os_log("\(self.t)🔍 Runtime class count=\(count)")

        if Self.verbose { os_log("\(self.t)🔍 Scanning classes for plugins...") }

        let classes = UnsafeBufferPointer(start: classList, count: Int(count))

        // 临时存储发现的插件，用于排序
        var discoveredPlugins: [(plugin: any SuperPlugin, className: String, order: Int)] = []

        for i in 0 ..< classes.count {
            let cls: AnyClass = classes[i]
            let className = NSStringFromClass(cls)

            // 只检查 GitOK 命名空间下以 "Plugin" 结尾的类
            guard className.hasPrefix("GitOK."), className.hasSuffix("Plugin") else { continue }

            // 尝试获取 shared 单例实例
            let sharedSelector = NSSelectorFromString("shared")
            guard let sharedMethod = class_getClassMethod(cls, sharedSelector) else {
                os_log("\(Self.t)⚠️ No @objc shared found for \(className), skipping")
                continue
            }

            // 调用 shared 方法获取实例
            typealias SharedGetter = @convention(c) (AnyClass, Selector) -> AnyObject?
            let getter = unsafeBitCast(method_getImplementation(sharedMethod), to: SharedGetter.self)

            guard let instance = getter(cls, sharedSelector) else {
                os_log("⚠️ Failed to get shared instance for \(className)")
                continue
            }

            // 检查实例是否符合 SuperPlugin 协议
            guard let plugin = instance as? any SuperPlugin else {
                os_log("⚠️ Instance of \(className) does not conform to SuperPlugin")
                continue
            }

            // 获取插件类型
            let pluginType = type(of: plugin)
            let pluginOrder = plugin.pluginOrder

            // 检查插件是否应该注册
            if !pluginType.shouldRegister {
                if Self.verbose { os_log("\(self.t)⏭️ Skipping plugin (shouldRegister=false): \(className)") }
                continue
            }

            // 添加到临时数组，稍后按 order 排序
            discoveredPlugins.append((plugin, className, pluginOrder))
        }

        // 按 order 排序后注册
        discoveredPlugins.sort { $0.order < $1.order }

        for (plugin, className, order) in discoveredPlugins {
            register(plugin)
            os_log("\(self.t)🧩 Registered plugin #\(order): \(className)")
        }

        os_log("\(self.t)✅ Startup end: autoDiscoverAndRegisterPlugins registered=\(self.registeredCount) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Plugin Query Methods

    /// 检查插件是否被用户启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        // 如果不允许用户切换，则始终启用
        if !plugin.pluginAllowUserToggle {
            return true
        }

        // 检查用户配置
        let pluginId = plugin.instanceLabel
        if PluginSettingsStore.shared.hasUserConfigured(pluginId) {
            return PluginSettingsStore.shared.isPluginEnabled(pluginId, defaultEnabled: plugin.pluginDefaultEnabled)
        }

        // 用户未配置过，使用插件的默认启用状态
        return plugin.pluginDefaultEnabled
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addTabItem() }
    }

    /// 获取可配置的插件信息列表（用于设置界面）
    /// - Returns: 允许用户切换启用/禁用状态的插件信息数组
    var configurablePlugins: [PluginInfo] {
        plugins
            .filter { $0.pluginAllowUserToggle }
            .map { plugin in
                let pluginId = plugin.instanceLabel
                let tableName = plugin.pluginTableName

                return PluginInfo(
                    id: pluginId,
                    name: String(localized: .init(stringLiteral: plugin.pluginDisplayName), table: tableName),
                    description: String(localized: .init(stringLiteral: plugin.pluginDescription), table: tableName),
                    icon: plugin.pluginIconName,
                    defaultEnabled: plugin.pluginDefaultEnabled,
                    isDeveloperEnabled: { true }
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    func getEnabledToolbarLeadingViews(
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        onSelectProject: @escaping GitOKProjectSelectionHandler = { _ in }
    ) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarLeadingView() else { return nil }
            return (
                plugin,
                AnyView(
                    view
                        .environment(\.gitOKProjects, projects)
                        .environment(\.gitOKSelectedProjectURL, selectedProjectURL)
                        .environment(\.gitOKSidebarVisible, isSidebarVisible)
                        .environment(\.gitOKProjectSelectionHandler, onSelectProject)
                )
            )
        }
        .loggingPluginViewBuild("toolbarLeading", start: start, logger: self)
    }

    /// 获取工具栏后置视图
    /// - Returns: 插件及其对应的工具栏后置视图数组
    func getEnabledToolbarTrailingViews(
        projectURL: URL? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        isGitRepository: Bool = false
    ) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarTrailingView() else { return nil }
            return (
                plugin,
                AnyView(
                    view
                        .environment(\.gitOKProjectURL, projectURL)
                        .environment(\.gitOKRemoteTrackingStatus, remoteTrackingStatus)
                        .environment(\.gitOKIsGitRepository, isGitRepository)
                )
            )
        }
        .loggingPluginViewBuild("toolbarTrailing", start: start, logger: self)
    }

    /// 获取插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 插件及其对应的列表视图数组
    func getEnabledPluginListViews(tab: String, project: Project?) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addListView(tab: tab, project: project) else { return nil }
            return (plugin, view)
        }
        .loggingPluginViewBuild("list tab=\(tab)", start: start, logger: self)
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    @MainActor
    func getEnabledTabDetailView(tab: String, projectURL: URL? = nil) -> AnyView? {
        let start = Date()
        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            if let view = plugin.addDetailView(for: tab) {
                let elapsed = Date().timeIntervalSince(start)
                if elapsed > 0.2 {
                    os_log("\(self.t)⏱️ Plugin detail view built tab=\(tab) plugin=\(plugin.instanceLabel) elapsed=\(String(format: "%.3f", elapsed))s")
                }
                return AnyView(view.environment(\.gitOKProjectURL, projectURL))
            }
        }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 0.2 {
            os_log("\(self.t)⏱️ Plugin detail view missing tab=\(tab) elapsed=\(String(format: "%.3f", elapsed))s")
        }
        return nil
    }

    // MARK: - StatusBar Views

    /// 获取状态栏前导视图
    /// - Returns: 启用插件的状态栏前导视图数组
    @MainActor
    func getEnabledStatusBarLeadingViews(selectedFilePath: String? = nil, projectPath: String? = nil) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarLeadingView() }
            .map { view in
                AnyView(
                    view
                        .environment(\.gitOKSelectedFilePath, selectedFilePath)
                        .environment(\.gitOKProjectPath, projectPath)
                )
            }
    }

    /// 获取状态栏中间视图
    /// - Returns: 启用插件的状态栏中间视图数组
    @MainActor
    func getEnabledStatusBarCenterViews(activityStatus: String? = nil) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarCenterView() }
            .map { view in
                AnyView(view.environment(\.gitOKActivityStatus, activityStatus))
            }
    }

    /// 获取状态栏后置视图
    /// - Returns: 启用插件的状态栏后置视图数组
    @MainActor
    func getEnabledStatusBarTrailingViews(
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false
    ) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarTrailingView() }
            .map { view in
                AnyView(
                    view
                        .environment(\.gitOKProjectURL, projectURL)
                        .environment(\.gitOKProjectPath, projectPath)
                        .environment(\.gitOKProjectTitle, projectTitle)
                        .environment(\.gitOKBranchName, branchName)
                        .environment(\.gitOKIsGitRepository, isGitRepository)
                )
            }
    }

    // MARK: - Theme Contributions

    @MainActor
    func getThemeContributions() -> [GitOKUIThemeContribution] {
        plugins.flatMap { plugin -> [GitOKUIThemeContribution] in
            guard isPluginEnabled(plugin) else { return [] }
            let pluginOrder = plugin.pluginOrder
            return plugin.addThemeContributions().map { contribution in
                GitOKUIThemeContribution(
                    sortKey: ThemeSortKey(pluginOrder: pluginOrder, themeId: contribution.id),
                    chromeTheme: contribution.chromeTheme,
                    editorThemeId: contribution.editorThemeId,
                    uiTheme: contribution.uiTheme,
                    attachments: contribution.attachments
                )
            }
        }
    }

    // MARK: - Root View Wrapper

    /// 获取所有插件的根视图包裹
    /// 将所有插件提供的根视图包装器依次应用于内容视图。
    /// 包装顺序与插件的 `order` 顺序一致。
    ///
    /// - Parameter content: 原始内容视图
    /// - Returns: 经过所有插件依次包裹后的视图
    func getRootViewWrapper<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        var wrapped: AnyView = AnyView(content())

        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            wrapped = plugin.wrapRoot(wrapped)
        }

        return wrapped
    }

    // MARK: - Initialization

    init() {
        let start = Date()
        os_log("\(Self.t)🚀 Startup begin: PluginVM.init")

        // 自动发现并注册所有插件
        autoDiscoverAndRegisterPlugins()
        registerPackagedPlugins()

        // 从内部注册表获取所有已注册的插件实例
        self.plugins = getAllPlugins()
        os_log("\(Self.t)✅ Startup step: PluginVM plugins sorted count=\(self.plugins.count)")

        // 订阅设置变化，当设置改变时触发 UI 更新
        settingsStore.$settings
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        os_log("\(Self.t)✅ Startup end: PluginVM.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    private func registerPackagedPlugins() {
        let activityStatus = PackagedPluginAdapter<PluginActivityStatus.ActivityStatusPlugin>()
        if type(of: activityStatus).shouldRegister {
            register(activityStatus)
        }
        let fileInfo = PackagedPluginAdapter<PluginFileInfo.FileInfoPlugin>()
        if type(of: fileInfo).shouldRegister {
            register(fileInfo)
        }
        let gitTab = PackagedPluginAdapter<PluginGitTab.GitTabPlugin>()
        if type(of: gitTab).shouldRegister {
            register(gitTab)
        }
        let iconTab = PackagedPluginAdapter<PluginIconTab.IconTabPlugin>()
        if type(of: iconTab).shouldRegister {
            register(iconTab)
        }
        let bannerTab = PackagedPluginAdapter<PluginBannerTab.BannerTabPlugin>()
        if type(of: bannerTab).shouldRegister {
            register(bannerTab)
        }
        let settingsButton = PackagedPluginAdapter<PluginSettingsButton.SettingsButtonPlugin>()
        if type(of: settingsButton).shouldRegister {
            register(settingsButton)
        }
        let openFinder = PackagedPluginAdapter<PluginOpenFinder.OpenFinderPlugin>()
        if type(of: openFinder).shouldRegister {
            register(openFinder)
        }
        let openTerminal = PackagedPluginAdapter<PluginOpenTerminal.OpenTerminalPlugin>()
        if type(of: openTerminal).shouldRegister {
            register(openTerminal)
        }
        let openCursor = PackagedPluginAdapter<PluginOpenCursor.OpenCursorPlugin>()
        if type(of: openCursor).shouldRegister {
            register(openCursor)
        }
        let openVSCode = PackagedPluginAdapter<PluginOpenVSCode.OpenVSCodePlugin>()
        if type(of: openVSCode).shouldRegister {
            register(openVSCode)
        }
        let openXcode = PackagedPluginAdapter<PluginOpenXcode.OpenXcodePlugin>()
        if type(of: openXcode).shouldRegister {
            register(openXcode)
        }
        let openGitHubDesktop = PackagedPluginAdapter<PluginOpenGitHubDesktop.OpenGitHubDesktopPlugin>()
        if type(of: openGitHubDesktop).shouldRegister {
            register(openGitHubDesktop)
        }
        let openTrae = PackagedPluginAdapter<PluginOpenTrae.OpenTraePlugin>()
        if type(of: openTrae).shouldRegister {
            register(openTrae)
        }
        let openKiro = PackagedPluginAdapter<PluginOpenKiro.OpenKiroPlugin>()
        if type(of: openKiro).shouldRegister {
            register(openKiro)
        }
        let openAntigravity = PackagedPluginAdapter<PluginOpenAntigravity.OpenAntigravityPlugin>()
        if type(of: openAntigravity).shouldRegister {
            register(openAntigravity)
        }
        let openRemote = PackagedPluginAdapter<PluginOpenRemote.OpenRemotePlugin>()
        if type(of: openRemote).shouldRegister {
            register(openRemote)
        }
        let themeStatusBar = PackagedPluginAdapter<PluginThemeStatusBar.ThemeStatusBarPlugin>()
        if type(of: themeStatusBar).shouldRegister {
            register(themeStatusBar)
        }
        let gitLFS = PackagedPluginAdapter<PluginGitLFS.GitLFSPlugin>()
        if type(of: gitLFS).shouldRegister {
            register(gitLFS)
        }
        let gitIgnore = PackagedPluginAdapter<PluginGitIgnore.GitIgnorePlugin>()
        if type(of: gitIgnore).shouldRegister {
            register(gitIgnore)
        }
        let readme = PackagedPluginAdapter<PluginReadme.ReadmePlugin>()
        if type(of: readme).shouldRegister {
            register(readme)
        }
        let license = PackagedPluginAdapter<PluginLicense.LicensePlugin>()
        if type(of: license).shouldRegister {
            register(license)
        }
        let cleanStatus = PackagedPluginAdapter<PluginCleanStatus.CleanStatusPlugin>()
        if type(of: cleanStatus).shouldRegister {
            register(cleanStatus)
        }
        let gitWatcher = PackagedPluginAdapter<PluginGitWatcher.GitWatcherPlugin>()
        if type(of: gitWatcher).shouldRegister {
            register(gitWatcher)
        }
        let gitPush = PackagedPluginAdapter<PluginGitPush.GitPushPlugin>()
        if type(of: gitPush).shouldRegister {
            register(gitPush)
        }
        let gitPull = PackagedPluginAdapter<PluginGitPull.GitPullPlugin>()
        if type(of: gitPull).shouldRegister {
            register(gitPull)
        }
        let gitSync = PackagedPluginAdapter<PluginGitSync.GitSyncPlugin>()
        if type(of: gitSync).shouldRegister {
            register(gitSync)
        }
        let autoPush = PackagedPluginAdapter<PluginAutoPush.AutoPushPlugin>()
        if type(of: autoPush).shouldRegister {
            register(autoPush)
        }
        let projectPicker = PackagedPluginAdapter<PluginProjectPicker.ProjectPickerPlugin>()
        if type(of: projectPicker).shouldRegister {
            register(projectPicker)
        }
        let smartMerge = PackagedPluginAdapter<PluginSmartMerge.SmartMergePlugin>()
        if type(of: smartMerge).shouldRegister {
            register(smartMerge)
        }
        let remoteRepository = PackagedPluginAdapter<PluginRemoteRepository.RemoteRepositoryPlugin>()
        if type(of: remoteRepository).shouldRegister {
            register(remoteRepository)
        }
        let branch = PackagedPluginAdapter<PluginBranch.BranchPlugin>()
        if type(of: branch).shouldRegister {
            register(branch)
        }
        let conflictResolver = PackagedPluginAdapter<PluginConflictResolver.ConflictResolverPlugin>()
        if type(of: conflictResolver).shouldRegister {
            register(conflictResolver)
        }
        let gitDetail = PackagedPluginAdapter<PluginGitDetail.GitDetailPlugin>(
            detailViewProvider: { tab in
                guard tab == PluginGitTab.GitTabPlugin.metadata.displayName else { return nil }
                return AnyView(GitDetail.shared)
            }
        )
        if type(of: gitDetail).shouldRegister {
            register(gitDetail)
        }
        let commit = PackagedPluginAdapter<PluginCommit.CommitPlugin>(
            listViewProvider: { tab, project in
                guard tab == "Git", let project, project.isGitRepo else { return nil }
                return AnyView(CommitList.shared)
            }
        )
        if type(of: commit).shouldRegister {
            register(commit)
        }
        let banner = PackagedPluginAdapter<PluginBanner.BannerPlugin>(
            detailViewProvider: { tab in
                guard tab == "Banner" else { return nil }
                return AnyView(PluginBanner.BannerDetailLayout.shared)
            }
        )
        if type(of: banner).shouldRegister {
            register(banner)
        }
        let icon = PackagedPluginAdapter<PluginIcon.IconPlugin>(
            detailViewProvider: { tab in
                guard tab == "Icon" else { return nil }
                return AnyView(PluginIcon.IconDetailLayout.shared)
            }
        )
        if type(of: icon).shouldRegister {
            register(icon)
        }
        let unpushedStatus = PackagedPluginAdapter<PluginUnpushedStatus.UnpushedStatusPlugin>()
        if type(of: unpushedStatus).shouldRegister {
            register(unpushedStatus)
        }
        let submodule = PackagedPluginAdapter<PluginSubmodule.SubmodulePlugin>()
        if type(of: submodule).shouldRegister {
            register(submodule)
        }
        let stash = PackagedPluginAdapter<PluginStash.StashPlugin>()
        if type(of: stash).shouldRegister {
            register(stash)
        }
        let themeGitOK = PackagedPluginAdapter<PluginThemeGitOK.GitOKThemePlugin>()
        if type(of: themeGitOK).shouldRegister {
            register(themeGitOK)
        }
        let themeSpring = PackagedPluginAdapter<PluginThemeSpring.SpringThemePlugin>()
        if type(of: themeSpring).shouldRegister {
            register(themeSpring)
        }

        let themeSummer = PackagedPluginAdapter<PluginThemeSummer.SummerThemePlugin>()
        if type(of: themeSummer).shouldRegister {
            register(themeSummer)
        }
        let themeWinter = PackagedPluginAdapter<PluginThemeWinter.WinterThemePlugin>()
        if type(of: themeWinter).shouldRegister {
            register(themeWinter)
        }
        let themeGraphite = PackagedPluginAdapter<PluginThemeGraphite.GraphiteThemePlugin>()
        if type(of: themeGraphite).shouldRegister {
            register(themeGraphite)
        }
        let themeDracula = PackagedPluginAdapter<PluginThemeDracula.DraculaThemePlugin>()
        if type(of: themeDracula).shouldRegister {
            register(themeDracula)
        }
        let themeOneDark = PackagedPluginAdapter<PluginThemeOneDark.OneDarkThemePlugin>()
        if type(of: themeOneDark).shouldRegister {
            register(themeOneDark)
        }
        let themeXcodeLight = PackagedPluginAdapter<PluginThemeXcodeLight.XcodeLightThemePlugin>()
        if type(of: themeXcodeLight).shouldRegister {
            register(themeXcodeLight)
        }
        let themeGitHubLight = PackagedPluginAdapter<PluginThemeGitHubLight.GitHubLightThemePlugin>()
        if type(of: themeGitHubLight).shouldRegister {
            register(themeGitHubLight)
        }
        let themeMatrix = PackagedPluginAdapter<PluginThemeMatrix.MatrixThemePlugin>()
        if type(of: themeMatrix).shouldRegister {
            register(themeMatrix)
        }
        let themeNebula = PackagedPluginAdapter<PluginThemeNebula.NebulaThemePlugin>()
        if type(of: themeNebula).shouldRegister {
            register(themeNebula)
        }
        let themeHarbor = PackagedPluginAdapter<PluginThemeHarbor.HarborThemePlugin>()
        if type(of: themeHarbor).shouldRegister {
            register(themeHarbor)
        }
        let themeOrchard = PackagedPluginAdapter<PluginThemeOrchard.OrchardThemePlugin>()
        if type(of: themeOrchard).shouldRegister {
            register(themeOrchard)
        }
        let themeGlacier = PackagedPluginAdapter<PluginThemeGlacier.GlacierThemePlugin>()
        if type(of: themeGlacier).shouldRegister {
            register(themeGlacier)
        }
        let themeMountain = PackagedPluginAdapter<PluginThemeMountain.MountainThemePlugin>()
        if type(of: themeMountain).shouldRegister {
            register(themeMountain)
        }
        let themeAurora = PackagedPluginAdapter<PluginThemeAurora.AuroraThemePlugin>()
        if type(of: themeAurora).shouldRegister {
            register(themeAurora)
        }
        let themeMidnight = PackagedPluginAdapter<PluginThemeMidnight.MidnightThemePlugin>()
        if type(of: themeMidnight).shouldRegister {
            register(themeMidnight)
        }
        let themeEmber = PackagedPluginAdapter<PluginThemeEmber.EmberThemePlugin>()
        if type(of: themeEmber).shouldRegister {
            register(themeEmber)
        }
        let themeRiver = PackagedPluginAdapter<PluginThemeRiver.RiverThemePlugin>()
        if type(of: themeRiver).shouldRegister {
            register(themeRiver)
        }
    }
}

private extension Array where Element == (plugin: SuperPlugin, view: AnyView) {
    func loggingPluginViewBuild(_ label: String, start: Date, logger: PluginVM) -> Self {
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 0.2 {
            os_log("\(logger.t)⏱️ Plugin views built type=\(label) count=\(self.count) elapsed=\(String(format: "%.3f", elapsed))s")
        }
        return self
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
