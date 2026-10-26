import Foundation
import Testing

/// 设置页样式一致性守卫。
///
/// ## 为什么需要它
///
/// 「项目」「外观」「插件管理」三个设置入口要与 Lumi 的观感一致。Lumi 把间距
/// 基准写死在 `.lumi/rules/settings-ui.md`（以「插件管理」页为基准）：
///
/// | 位置 | 数值 |
/// |------|------|
/// | 列表栏宽度 | 300 |
/// | 主从容器高度 | 占满剩余空间（**不得写死下限**） |
/// | 详情栏内容内边距 | 22 |
/// | 页面底部留白 | 贴边分栏页不需要 |
///
/// 这些数值都是 SwiftUI 修饰符里的字面量（`300` / `520` / `22` …），不产出任何
/// 可断言的运行时对象，因此这里直接审计源码：
///
/// - **正向**：页面必须出现基准值——防止某个页面被悄悄改小 / 改大；
/// - **反向**：页面不得出现已登记的偏差值——防止「改回去了」；
/// - **卡片体系**：分组一律走原生 `AppSettingSection`（标题在卡内、行间一条
///   `Divider()`），不得再出现自绘的玻璃拟态卡片家族。
///
/// 「外观」页的视图由外部包 `LumiThemePack` 提供（本仓库无源码），因此改为
/// 校验锁定版本：低于 Lumi 用的 1.0.12 就拿不到那一版的贴边布局。
@Suite("设置页样式一致性")
struct SettingsStyleConformanceTests {

    // MARK: - 基准值（与 Lumi 仓 SettingsLayoutConformanceTests 一致）

    /// 列表栏宽度。
    private static let listWidth = 300
    /// 主从容器不得写死的最小高度。
    private static let splitMinHeight = 520
    /// 详情栏内容内边距。
    private static let detailPadding = 22
    /// 曾经出现过的错误列表栏宽度。
    private static let staleListWidths = [280, 320, 340]
    /// 曾经出现过的错误主从容器最小高度。
    private static let staleMinHeights = [300, 460, 560]
    /// 自绘新卡片家族（玻璃拟态、标题在卡外、每行一个独立圆角块）。
    ///
    /// 注意：这些名字与原生家族只差一个字母（`AppSettings…` vs `AppSetting…`），
    /// 匹配时必须带右括号，否则两者会互相命中。
    private static let customCardComponents = [
        "AppCard",
        "AppSettingsSection(",
        "AppSettingsRow(",
        "AppSettingsToggleRow(",
        "AppSettingsStepperRow(",
        "AppSettingsPickerRow(",
        "AppSettingsSegmentedPickerRow(",
        "AppSettingsReadOnlyRow(",
        "AppSettingsSecureFieldRow(",
    ]
    /// 「外观」页所在的远程包，以及 Lumi 对齐所用的版本下限。
    private static let appearancePackageIdentity = "lumithemepack"
    private static let appearanceMinimumVersion = "1.0.12"
    /// 「插件管理」页所在的远程包，支持宿主注入插件 id 的版本下限。
    ///
    /// 1.3.0 起提供 `init(id:)`；此前版本把插件 id 写死为上游品牌。
    private static let pluginManagerMinimumVersion = "1.3.0"

    // MARK: - 受审页面

    /// 受审的设置入口详情页。
    private struct AuditedPage {
        /// 设置入口对应的详情视图类型名（用于完整性检查）。
        let viewTypeNames: [String]
        /// 相对仓库根的源码路径（页面主体）。
        let path: String
        /// 与该入口同属一个页面的其他文件（详情面板 / 外层容器），
        /// 断言会连同页面主体一起检查。
        let relatedPaths: [String]
        /// 详情栏内容内边距所在文件。
        let detailPaddingPath: String?
        /// 页面正文是否必须使用原生 `AppSettingSection` 分组卡片。
        ///
        /// 插件管理页的正文是插件贡献的 about 视图（由各插件自行决定卡片形态），
        /// 不做要求；项目页的正文由本仓库实现，必须走原生分组卡片。
        let requiresNativeSection: Bool

        init(
            viewTypeNames: [String],
            path: String,
            relatedPaths: [String] = [],
            detailPaddingPath: String? = nil,
            requiresNativeSection: Bool = false
        ) {
            self.viewTypeNames = viewTypeNames
            self.path = path
            self.relatedPaths = relatedPaths
            self.detailPaddingPath = detailPaddingPath
            self.requiresNativeSection = requiresNativeSection
        }
    }

    /// 「项目」页：本仓库内实现，主体与详情面板同在一个文件。
    private static let auditedPages: [AuditedPage] = [
        AuditedPage(
            viewTypeNames: ["ProjectsSettingsDetailView"],
            path: "Packages/PluginProjects/Sources/PluginProjects/Views/ProjectsSettingsDetailView.swift",
            detailPaddingPath: "Packages/PluginProjects/Sources/PluginProjects/Views/ProjectsSettingsDetailView.swift",
            requiresNativeSection: true
        ),
    ]

    // MARK: - 用例

    @Test("项目 / 插件管理页遵循 Lumi 的主从分栏基准间距")
    func auditedPagesMatchBaseline() throws {
        let root = try Self.repositoryRoot()
        var failures: [String] = []

        for page in Self.auditedPages {
            let source = try Self.source(root: root, path: page.path)
            var combinedSource = source
            for relatedPath in page.relatedPaths {
                combinedSource += try Self.source(root: root, path: relatedPath)
            }

            // 列表栏宽度。
            if !source.contains(".frame(width: \(Self.listWidth))") {
                failures.append("- \(page.path)：列表栏宽度应为 \(Self.listWidth)")
            }
            // 主从容器必须吃满剩余空间。
            if !source.contains(".frame(maxHeight: .infinity)") {
                failures.append("- \(page.path)：主从容器必须用 .frame(maxHeight: .infinity) 占满剩余空间")
            }
            // 主从容器不得写死下限：页面比窗口高时，外层容器被撑大，窗口按居中裁切，
            // 顶部与底部同时被切掉（顶部卡片标题会整块消失）。
            if source.contains(".frame(minHeight: \(Self.splitMinHeight)") {
                failures.append(
                    "- \(page.path)：主从容器不得写死 minHeight: \(Self.splitMinHeight)"
                    + "（会让整页超出窗口并被居中裁切，只保留 maxHeight: .infinity 即可）"
                )
            }
            // 详情栏内容内边距。
            if let detailPaddingPath = page.detailPaddingPath {
                let detailSource = try Self.source(root: root, path: detailPaddingPath)
                if !detailSource.contains(".padding(\(Self.detailPadding))") {
                    failures.append("- \(detailPaddingPath)：详情栏内容内边距应为 \(Self.detailPadding)")
                }
            }
            // 贴边分栏页必须直接用共享 scaffold：`PluginSettingsScaffold` 会在内容外
            // 多包一层 `VStack(spacing: 24)` + `Spacer`，那 24pt 会从内容区里被吃掉，
            // 主从容器比内容区矮一截，竖直分隔线到不了窗口底部。
            let code = String(Self.blankOutStringsAndComments(combinedSource))
            if code.contains("PluginSettingsScaffold") {
                failures.append(
                    "- \(page.path)：贴边分栏页不得使用 PluginSettingsScaffold"
                    + "（会吃掉 24pt 高度，竖直分隔线到不了窗口底部），"
                    + "应改用 AppSettingsContentScaffold(scrollsContent: false, maxContentWidth: nil)"
                )
            }
            // 已登记的偏差值不得复活。
            for stale in Self.staleListWidths {
                if source.contains(".frame(width: \(stale))") {
                    failures.append("- \(page.path)：列表栏宽度仍是 \(stale)，应为 \(Self.listWidth)")
                }
            }
            for stale in Self.staleMinHeights {
                if source.contains("minHeight: \(stale)") {
                    failures.append("- \(page.path)：主从容器最小高度仍是 \(stale)")
                }
            }
        }

        if !failures.isEmpty {
            Issue.record(
                Comment(rawValue: """
                设置入口详情页与 Lumi 的「插件管理」基准不一致：

                \(failures.joined(separator: "\n"))
                """)
            )
        }
    }

    @Test("项目 / 插件管理页统一使用原生 GroupBox 卡片体系")
    func settingsPagesUseNativeGroupBoxCards() throws {
        let root = try Self.repositoryRoot()
        var failures: [String] = []

        for page in Self.auditedPages {
            var paths = [page.path]
            paths.append(contentsOf: page.relatedPaths)
            if let detailPaddingPath = page.detailPaddingPath {
                paths.append(detailPaddingPath)
            }

            for path in paths {
                let source = try Self.source(root: root, path: path)
                // 先把注释与字符串字面量涂成空格，避免「注释里提到组件名」被误判。
                let code = String(Self.blankOutStringsAndComments(source))

                // 1) 不得再出现自绘新卡片家族（玻璃拟态卡片）。
                for custom in Self.customCardComponents {
                    if code.contains(custom) {
                        failures.append(
                            "- \(path)：仍在使用自绘卡片组件 \(custom)，"
                            + "设置页应改用原生 AppSettingSection + AppSettingRow + 行间 Divider()"
                        )
                    }
                }

                // 2) 不得手写 GroupBox（分组一律走 `AppSettingSection`）。
                if code.contains("GroupBox {") {
                    failures.append("- \(path)：仍在手写 GroupBox，应改用 AppSettingSection")
                }

                // 3) 需要原生分组的页面必须真的用上了原生家族，否则「没有自绘卡片」
                //    也可能只是压根没有分组卡片。
                if path == page.path,
                   page.requiresNativeSection,
                   !code.contains("AppSettingSection(") {
                    failures.append("- \(path)：未使用原生 AppSettingSection 分组卡片")
                }
            }
        }

        if !failures.isEmpty {
            Issue.record(
                Comment(rawValue: """
                设置入口详情页仍在使用自绘新卡片体系：

                \(failures.joined(separator: "\n"))
                """)
            )
        }
    }

    @Test("插件管理页锁定在支持宿主 id 注入的 LumiPluginPluginManager 版本")
    func pluginManagerPageUsesHostInjectableRemotePackage() throws {
        let root = try Self.repositoryRoot()
        var failures: [String] = []

        // 依赖声明：FactoryGitOK 声明的版本下限不得低于支持 `init(id:)` 的版本。
        //
        // 1.2.0 之前的远程包把插件 id 写死为 `com.coffic.lumi.plugin.plugin-manager`，
        // GitOK 复用后会在插件管理页与内核注册表里残留上游品牌；1.3.0 才提供
        // `init(id:)` 让宿主注入自己的品牌 id。
        let manifestPath = root.appendingPathComponent("Packages/FactoryGitOK/Package.swift")
        let manifest = try String(contentsOf: manifestPath, encoding: .utf8)
        let declarationPattern = #"LumiPluginPluginManager\.git"\s*,\s*from:\s*"([^"]+)""#
        guard let declarationRange = manifest.range(of: declarationPattern, options: .regularExpression) else {
            Issue.record(Comment(rawValue: "未能在 \(manifestPath.path) 中找到 LumiPluginPluginManager 的版本声明"))
            return
        }
        guard let declarationVersion = Self.capture(in: manifest, range: declarationRange, pattern: declarationPattern) else {
            Issue.record(Comment(rawValue: "未能解析 LumiPluginPluginManager 的版本声明"))
            return
        }
        if Self.compareVersions(declarationVersion, Self.pluginManagerMinimumVersion) < 0 {
            failures.append(
                "- Packages/FactoryGitOK/Package.swift：LumiPluginPluginManager 声明为 \(declarationVersion)，"
                + "低于 \(Self.pluginManagerMinimumVersion)（该版本才支持宿主注入插件 id）"
            )
        }

        // 宿主必须真的注入自己的品牌 id，否则界面与内核注册表仍是上游品牌。
        if !manifest.contains("PluginPluginManager") {
            failures.append("- Packages/FactoryGitOK/Package.swift：未引用 PluginPluginManager 远程包")
        }
        let factoryPath = root.appendingPathComponent("Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift")
        let factory = try String(contentsOf: factoryPath, encoding: .utf8)
        if !factory.contains(#"PluginPluginManager(id: "com.coffic.gitok.plugin.plugin-manager")"#) {
            failures.append(
                "- Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift："
                + "插件管理插件未注入 GitOK 品牌 id（会残留 com.coffic.lumi 上游品牌）"
            )
        }

        if !failures.isEmpty {
            Issue.record(
                Comment(rawValue: """
                插件管理页未锁定在支持宿主 id 注入的远程包版本：

                \(failures.joined(separator: "\n"))
                """)
            )
        }
    }

    @Test("外观页锁定在 Lumi 对齐所用的 LumiThemePack 版本")
    func appearancePageUsesAlignedThemePackVersion() throws {
        let root = try Self.repositoryRoot()
        var failures: [String] = []

        // 依赖声明：FactoryGitOK 声明的版本下限不得低于对齐版本。
        let manifestPath = root.appendingPathComponent("Packages/FactoryGitOK/Package.swift")
        let manifest = try String(contentsOf: manifestPath, encoding: .utf8)
        let declarationPattern = #"LumiThemePack\.git"\s*,\s*from:\s*"([^"]+)""#
        guard let declarationRange = manifest.range(of: declarationPattern, options: .regularExpression) else {
            Issue.record(Comment(rawValue: "未能在 \(manifestPath.path) 中找到 LumiThemePack 的版本声明"))
            return
        }
        guard let declarationVersion = Self.capture(in: manifest, range: declarationRange, pattern: declarationPattern) else {
            Issue.record(Comment(rawValue: "未能解析 LumiThemePack 的版本声明"))
            return
        }
        if Self.compareVersions(declarationVersion, Self.appearanceMinimumVersion) < 0 {
            failures.append(
                "- Packages/FactoryGitOK/Package.swift：LumiThemePack 声明为 \(declarationVersion)，"
                + "低于 \(Self.appearanceMinimumVersion)（该版本才把外观页改成贴边分栏）"
            )
        }

        // 锁定版本：workspace 级 pin 不得低于对齐版本。
        let resolvedPath = root.appendingPathComponent(
            "GitOK.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        if FileManager.default.fileExists(atPath: resolvedPath.path) {
            let data = try Data(contentsOf: resolvedPath)
            let object = try JSONSerialization.jsonObject(with: data)
            guard let root = object as? [String: Any],
                  let pins = root["pins"] as? [[String: Any]]
            else {
                Issue.record(Comment(rawValue: "无法解析 \(resolvedPath.path)"))
                return
            }
            guard let pin = pins.first(where: { ($0["identity"] as? String) == Self.appearancePackageIdentity }),
                  let state = pin["state"] as? [String: Any],
                  let version = state["version"] as? String
            else {
                Issue.record(Comment(rawValue: "\(resolvedPath.path) 中没有 \(Self.appearancePackageIdentity) 的锁定版本"))
                return
            }
            if Self.compareVersions(version, Self.appearanceMinimumVersion) < 0 {
                failures.append(
                    "- Package.resolved：\(Self.appearancePackageIdentity) 锁定在 \(version)，"
                    + "低于 \(Self.appearanceMinimumVersion)"
                )
            }
        }

        if !failures.isEmpty {
            Issue.record(
                Comment(rawValue: """
                外观页未对齐到 Lumi 使用的 LumiThemePack 版本：

                \(failures.joined(separator: "\n"))
                """)
            )
        }
    }

    // MARK: - 源码扫描工具

    /// 从本测试文件所在位置向上找仓库根（含 `GitOK.xcodeproj` 的目录）。
    private static func repositoryRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.pathComponents.count > 1 {
            if FileManager.default.fileExists(
                atPath: url.appendingPathComponent("GitOK.xcodeproj").path
            ) {
                return url
            }
            url.deleteLastPathComponent()
        }
        throw RepositoryRootNotFoundError()
    }

    private static func source(root: URL, path: String) throws -> String {
        let url = root.appendingPathComponent(path)
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// 取出正则第一个捕获组。
    private static func capture(in source: String, range: Range<String.Index>, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: source, range: NSRange(range, in: source)),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: source)
        else {
            return nil
        }
        return String(source[captureRange])
    }

    /// 比较形如 `1.0.12` 的版本号：a < b 返回负数，相等返回 0。
    private static func compareVersions(_ lhs: String, _ rhs: String) -> Int {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l < r ? -1 : 1 }
        }
        return 0
    }

    /// 把字符串字面量与注释替换成空格（保留换行，长度与行号不变）。
    ///
    /// 扫描组件名时必须先做这一步：注释里写「不能套 PluginSettingsScaffold」
    /// 这样的说明，被当成真实调用就会误报。
    private static func blankOutStringsAndComments(_ source: String) -> [Character] {
        var result = Array(source)
        var index = 0
        let count = result.count

        func blank(_ range: Range<Int>) {
            for position in range where position < count {
                if result[position] != "\n" {
                    result[position] = " "
                }
            }
        }

        func matches(_ needle: String, at position: Int) -> Bool {
            let characters = Array(needle)
            guard position + characters.count <= count else { return false }
            return Array(result[position..<(position + characters.count)]) == characters
        }

        while index < count {
            if result[index] == "\"" {
                if matches("\"\"\"", at: index) {
                    var cursor = index + 3
                    while cursor < count && !matches("\"\"\"", at: cursor) { cursor += 1 }
                    cursor = min(cursor + 3, count)
                    blank(index..<cursor)
                    index = cursor
                } else {
                    var cursor = index + 1
                    while cursor < count {
                        if result[cursor] == "\\" { cursor += 2; continue }
                        if result[cursor] == "\"" { cursor += 1; break }
                        if result[cursor] == "\n" { break }
                        cursor += 1
                    }
                    blank(index..<min(cursor, count))
                    index = min(cursor, count)
                }
            } else if matches("//", at: index) {
                var cursor = index
                while cursor < count && result[cursor] != "\n" { cursor += 1 }
                blank(index..<cursor)
                index = cursor
            } else if matches("/*", at: index) {
                var cursor = index + 2
                while cursor < count && !matches("*/", at: cursor) { cursor += 1 }
                cursor = min(cursor + 2, count)
                blank(index..<cursor)
                index = cursor
            } else {
                index += 1
            }
        }
        return result
    }

    private struct RepositoryRootNotFoundError: Error {}
}
