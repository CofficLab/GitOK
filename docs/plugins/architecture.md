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
    ├─► GitOKPluginBootstrap.configureRuntimes(projectService:)
    │
    ▼
PluginService.init()
    │
    ▼
GeneratedPluginRegistry.registerAll(into: runtime)
    │
    ▼
GitOKPluginRuntime.register(any GitOKPlugin.Type)
    │
    ▼
ContentView queries PluginService for toolbar / list / detail / statusbar
```

**注意：** 不再使用 Objective-C Runtime 自动扫描。所有插件必须在 `GeneratedPluginRegistry` 中显式注册。

## 插件协议

- **`GitOKPlugin`** — 静态 enum 协议（`metadata`、`toolbarTrailingItems` 等）
- **`GitOKPluginContext`** — 向插件视图注入运行时快照、回调与 `resolve()` DI
- **`GitOKPluginDependencies`** — 注册 `GitOKProjectServicing`、`GitOKNavigationServicing` 等 App 服务

菜单导航与 Git 命令通过 `GitOKNavigationServicing` / `GitOKGitCommandServicing` 走 App 服务层。

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
