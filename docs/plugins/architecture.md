# GitOK 插件系统架构

> 状态：SPM 显式注册（`GeneratedPluginRegistry` + `GitOKPluginRuntime`）  
> App 壳：`GitOKApp/` — 详见 [gitok-app-shell.md](../architecture/gitok-app-shell.md)

## 系统概览

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         GitOKApp (thin shell)                        │
│  RootContainer → PluginService → ContentView (NavigationSplitView)   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│              GitOKPluginRegistry / GeneratedPluginRegistry           │
│              显式 import 各 Plugins/* SPM 包                          │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Plugins/*Plugin  →  static GitOKPlugin enum  →  GitOKPluginRuntime   │
└─────────────────────────────────────────────────────────────────────┘
```

## 插件注册流程

```text
App Launch
    │
    ▼
RootContainer.shared
    │
    ├─► 注册 App 服务到 GitOKPluginDependencies（Project/Activity/GitCommand/Theme/Navigation）
    │
    ├─► GitOKPluginBootstrap.configureRuntimes(projectService:)
    │
    ▼
PluginService.init()
    │
    ▼
GeneratedPluginRegistry.registerAll(into: runtime)
    │
    ▼
PluginService.startupPlugins() → GitOKPluginRuntime.startup(dependencies:)
    │
    ├─► ① onBoot(dependencies:)   — 全部启用插件同步注册自有服务
    ├─► ② 校验 GitOKRequiredServices — 缺失则抛 missingRequiredServices 并列出清单
    └─► ③ onReady(context:)       — 依赖其他服务的插件初始化
    │
    ▼
ContentView queries PluginService for toolbar / list / detail / statusbar
```

**注意：** 不再使用 Objective-C Runtime 自动扫描。所有插件必须在 `GeneratedPluginRegistry` 中显式注册。

## 插件协议

- **`GitOKPlugin`** — 静态 enum 协议（`metadata`、`onBoot`、`onReady`、`toolbarTrailingItems` 等）
- **`GitOKPluginContext`** — 向插件视图注入运行时快照、回调与 `resolve()` DI
- **`GitOKPluginDependencies`** — 类型键控服务注册表，注册 `GitOKProjectServicing`、`GitOKNavigationServicing` 等 App 服务

菜单导航与 Git 命令通过 `GitOKNavigationServicing` / `GitOKGitCommandServicing` 走 App 服务层。

## Order 分带约定

插件 `metadata.order` 决定注册与贡献排序，按 Lumi 内核规范分带：

| 分带 | 含义 | 示例 |
|------|------|------|
| `0–99` | 核心（应用骨架，alwaysOn） | ProjectsPlugin(10)、OnboardingPlugin(20)、ProjectPickerPlugin(80) |
| `100–199` | 基础服务（设置、状态） | GitNetworkSettingsPlugin(110)、ActivityStatusPlugin(160) |
| `200–299` | Git 功能 | GitDetailPlugin(220)、GitBranchPlugin(230)、GitStashPlugin(240) |
| `300+` | 可选增强（optIn / 主题 / Open-In） | LicensePlugin(310)、Theme*(330+)、Open*(400+) |

新增插件按归属分带取值；同带内保持 10 的步长便于插入。

## 贡献 ID 纪律

所有贡献项 `id` 必须是插件前缀的稳定标识（如 `metadata.id` 或 `"plugin-id.slot"`），
禁止裸 UI 文案或临时字符串，保证排序与调试可追溯。`Scripts/check-plugin-package-boundaries.sh`
与 `GitOKPluginRegistry` 的守护测试负责校验。

## 贡献点

| 贡献点 | 方法 | 挂载位置 |
|--------|------|----------|
| Tab | `tabItems(context:)` | ContentView 标签栏 |
| List | `listPaneItems(context:tab:)` | NavigationSplitView 左栏 |
| Detail | `detailPaneItems(context:tab:)` | NavigationSplitView 右栏 |
| Sidebar | `sidebarPaneItems(context:)` | 侧边栏 |
| Onboarding | `onboardingPaneItems(context:)` | Detail 空态 |
| Settings | `settingsPaneItems(context:)` | 设置页 |
| Toolbar | `toolbarLeadingItems` / `toolbarTrailingItems` | 工具栏 |
| StatusBar | `statusBar*Items` | 底部状态栏 |
| Theme | `themeContributions(context:)` | ThemeService |
| Root | `rootOverlay(context:content:)` | RootView 包裹层 |

## 依赖规则

- `Plugins/*` **不得** `import GitOKApp`
- `GitOKCoreKit` **不得** import 任何 Feature Plugin
- 唯一源码根：`Plugins/<Name>Plugin/`（`Packages/Plugin*` 镜像已废弃）
