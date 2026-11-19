# GitOK 插件系统架构

> 状态：宿主清单 + LumiFactory 装配（`GitOKHostManifest` + `GitOKPluginCatalog`）  
> App 壳：`GitOKApp/` — 详见 [gitok-app-shell.md](../architecture/gitok-app-shell.md)

## 系统概览

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         GitOKApp (thin shell)                        │
│  GitOKHostManifest（品牌/存储/主题/接线） + GitOKPluginCatalog（目录） │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ KernelBootstrapper(manifest:)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│        LumiFactory.KernelAssembler（远程共享装配引擎）                 │
│        基线 Provider → registerProviders → 插件启动 → 视图接线         │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ kernel.startAsync(plugins:)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Plugins/*Plugin（SuperPlugin）→ 向 Kernel 注册能力 Provider           │
│  宿主视图（RootView / 工具栏 / 设置 / 状态栏）resolve Provider 渲染     │
└─────────────────────────────────────────────────────────────────────┘
```

## 插件注册流程

```text
App Launch
    │
    ▼
GitOKApp.init → KernelBootstrapper(manifest: GitOKHostManifest.make { … })
    │
    ▼
KernelAssembler.makeKernel(manifest:)
    │
    ├─► ① 基线 Provider（存储/主题/根视图/设置/菜单栏等，跨 App 一致）
    ├─► ② 存储与基础设施迁移
    ├─► ③ manifest.registerProviders — GitOK 特有能力（Git/项目/导航等）
    ├─► ④ manifest.makePlugins() → GitOKPluginCatalog.makePlugins()
    │       可选 pluginFilter 过滤 + HostPluginMigration 迁移
    ├─► ⑤ kernel.startAsync(plugins:)
    │       排除 policy == .disabled → 依赖拓扑 + order 排序
    │       逐个 onRegister → onBoot → onReady（缺失依赖即抛错）
    ├─► ⑥ 设置首选项重置为 order 最小入口
    └─► ⑦ 共享视图接线 + manifest.wireKernel
    │
    ▼
HostMacScenes 渲染 loading / ready / failed 三态
```

**注意：** 不使用 Objective-C Runtime 自动扫描。所有插件必须在
`GitOKApp/GitOKPluginCatalog.swift` 中显式列出，并在
`GitOK.xcodeproj/project.xcproj` 声明包与产品依赖。

## 插件契约（LumiKernel.SuperPlugin）

- `id` / `order` / `dependencies` / `metadata`（含 `policy`：alwaysOn / optIn / disabled）
- 生命周期：`onRegister` → `onBoot` → `onReady` → `onShutdown` → `onUnregister`，
  启用/禁用回调 `onEnable` / `onDisable`；`AsyncSuperPlugin` 提供 async 变体
- 插件在 `onBoot` 向 Kernel **注册或替换能力 Provider**，不直接持有视图；
  宿主视图与其他插件通过 `kernel.resolveProvider(...)` 消费能力
- 根视图是**宿主 Provider**：`manifest.makeRootViewProvider` 提供
  `GitOKRootViewProvider`，`RootViewPlugin` 只向其贡献工作区门控
  （noProject / projectMissing / cloning / cloneFailed / notGitRepository / ready）

## 启动排序

`kernel.startAsync` 先按 `dependencies` 做拓扑校验（缺失即抛
`pluginDependencyMissing`），再按 `order` 升序启动，同序保持目录数组顺序。
`order` 是目录内的相对值（当前 0–100，如 ProjectsPlugin(0)、LicensePlugin(45)）；
新增插件取值时保证依赖方在前、同带留有余量即可。

## 贡献 ID 纪律

所有贡献项 `id` 必须是插件前缀的稳定标识（如 `metadata.id` 或 `"plugin-id.slot"`），
禁止裸 UI 文案或临时字符串，保证排序与调试可追溯；由 `GitOKTests` 守护测试校验。

## 贡献面

插件通过能力 Provider 贡献 UI，宿主视图统一消费：

| 贡献面 | 载体协议 | 挂载位置 |
|--------|----------|----------|
| 侧边栏列表 | `SidebarProviding` / `ProjectSidebarProviding` | NavigationSplitView 左栏 |
| 设置入口 | `SettingViewProviding` | 设置窗口 |
| 工具栏 | `ToolbarProviding` | 主窗口工具栏 |
| 状态栏 | `StatusBarProviding` | 底部状态栏 |
| 右栏 Rail | `RailViewProviding` | 右侧面板 |
| 主题 | `ThemeProviding` | 主题目录与选色 |
| 根视图门控/覆盖层 | `RootViewProviding` | RootView 工作区 |
| 关于/文档 | `DocsViewProviding` | 关于页 |

菜单导航与 Git 命令通过 `GitOKNavigationServicing` / `GitOKGitCommandServicing` 走 App 服务层。

## 依赖规则

- `Packages/Plugin*` **不得** `import GitOKApp`
- `KitGitOKCore` **不得** import 任何 Feature Plugin
- 一个插件一个 SPM 包：`Packages/Plugin<Name>/`，加入目录的同时必须在
  `GitOK.xcodeproj/project.xcproj` 的 **GitOK 与 GitOKTests 两个 target**
  声明同一产品（测试构建按产品生成动态框架；只链入 App 的本地产品会静态
  合并共享依赖的目标代码，与测试框架产生类型身份分裂，Provider 解析失效）
- 本地包产品名不得与远程共享包产品重名（测试构建按产品名生成动态框架，
  重名会触发 "Multiple commands produce"）；本地根视图产品因此命名为
  `GitOKProviderRootView`（模块同名），与 LumiProviders 的 `ProviderRootView` 区分