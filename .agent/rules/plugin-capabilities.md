# 插件 Capabilities 能力边界规范

> 本规范定义 GitOK 插件如何声明自己**消费外部能力**的最小边界。
> 参考兄弟项目 Lumi / Cisum 的同名机制，核心目的：让 View / ViewModel / Observer
> 不再直接依赖 `any *Providing` 宽接口。

---

## 核心原则

**插件依赖的是「自己声明的窄能力」，不是「内核的宽 Provider」。**

一个插件对外界（内核 Provider、其他插件的 Provider）的所有依赖，都应收敛到本插件
`Capabilities/` 目录下的 `protocol XxxCapability` + `XxxCapabilityAdapter`。
View / ViewModel / Observer 只面向该窄协议编程。

> 外部能力进入插件的唯一入口是**能力协议 + Adapter**（依赖收窄），
> 外部状态进入插件的唯一入口是**Observer**（状态收窄）。两者互补、不冲突：
> Observer 负责「状态怎么进来」，Capabilities 负责「接口怎么收窄」。

---

## 1. 目录位置

| 包结构 | 位置 |
|--------|------|
| 有包裹目录（`Sources/<PackageName>/`，GitOK 全部插件） | `Sources/<PackageName>/Capabilities/` |

每个能力一个文件，文件名 = 主类型名，例如 `GitDiffProjectCapability.swift`。

目录与 `Observers/`、`ViewModels/`、`Views/` 平级。

---

## 2. 与 `Providers/` 的区别（关键，别混淆）

GitOK 中两个目录方向**相反**：

| 目录 | 方向 | 内容 | 例 |
|------|------|------|------|
| `Providers/` | **生产**：本插件向外**提供**能力 | 实现内核的 `*Providing` 协议 | `PluginStorage/Providers/StorageProvider.swift` |
| `Capabilities/` | **消费**：本插件向**内**索取能力 | 声明本插件**需要的**窄接口 + Adapter | `PluginGitDiff/Capabilities/GitDiffProjectCapability.swift` |

一句话：`Providers/` 是我给别人什么，`Capabilities/` 是我需要什么。

---

## 3. 标准写法

以 `PluginGitDiff` 为参考实现：

```swift
import Foundation
import KitGit
import ProviderProjects

/// Git Diff 插件读取项目选择状态的最小能力。
@MainActor
protocol GitDiffProjectCapability: AnyObject {
    var currentCommit: GitCommit? { get }
    var currentProjectURL: URL? { get }
    var currentFile: String? { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将 ProjectProviding 收窄成 Git Diff 所需的能力。
@MainActor
final class GitDiffProjectCapabilityAdapter: GitDiffProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentCommit: GitCommit? { projects.currentCommit }
    var currentProjectURL: URL? { projects.currentProject?.url }
    var currentFile: String? { projects.currentFile }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }
}
```

### 命名规范

| 角色 | 命名 |
|------|------|
| 协议 | `<Plugin前缀><Domain>Capability`，如 `GitDiffProjectCapability`、`BannerSceneCapability` |
| 适配器 | 协议名 + `Adapter`，如 `GitDiffProjectCapabilityAdapter` |
| 事件枚举 | `<Domain>Event`，如 `PendingMessageSendingEvent` |
| 观察句柄 | `<Domain>ObserverHandle`，如 `PendingMessageSendingObserverHandle` |

> 多个能力共用同一 Provider 时，前缀区分用途而非 Provider 本身
> （GitOK 中的 `IconSceneCapability` 与 `IconProjectCapability` 是典型例子）。
> 插件前缀可省略当包名已隐含唯一性时（如 `PluginBanner/Capabilities/BannerSceneCapability.swift`
> 保留前缀是因为 `Scene` 域在多插件间复用）。

### 可见性

| 场景 | 修饰符 |
|------|--------|
| 能力仅本插件内部消费 | `internal`（默认，不写修饰符） |
| 能力需被本包 `Tests` 使用 | `public` |
| 能力需被**其他插件**消费 | 不属于本机制 —— 应下沉为 `Provider*` / `Kit*` 包 |

---

## 4. 装配规则

Adapter 一律在插件入口的 `onBoot(kernel:)` 中创建并注入 ViewModel / View / Observer。

```swift
public final class GitDiffPlugin: SuperPlugin {
    /// 插件自有 ViewModel：由外部 Observer 驱动，视图只绑定它。
    private var viewModel: GitDiffViewModel?
    /// 插件级外部 Observer：装配阶段创建并持有，卸载时取消。
    private var observer: GitDiffObserver?

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered")
            return
        }

        let capability = GitDiffProjectCapabilityAdapter(projects: projects)
        let viewModel = GitDiffViewModel()
        self.viewModel = viewModel
        // ... 用 capability 的初始快照决定面板初始可见性等
    }
}
```

### ⚠️ 生命周期陷阱：Adapter 无人持有会静默失效

如果 Adapter 只是**临时创建后直接注入**，且没有任何强引用持有它，
Adapter 会随 `onBoot` 返回立即释放，消费方的 `weak` 全部落空（功能静默失效）。

```swift
// ❌ 错误：Adapter 无人持有；如果注入方用 weak 接收，功能永远不生效
let viewModel = MyViewModel(capability: MyCapabilityAdapter(projects: projects))

// ✅ 正确：入口显式强持有 Adapter，并在 onUnregister / shutdown 释放
private var capability: MyProjectCapability?
...
let capability = MyProjectCapabilityAdapter(projects: projects)
self.capability = capability
let viewModel = MyViewModel(capability: capability)
```

判断标准：**如果消费方不持有 Adapter（或持有为 `weak`），入口必须持有。**
若消费方以强引用存进 ViewModel 且 ViewModel 被入口持有，则 Adapter 随 ViewModel 存活，可不强持。

### 与 Observer 的分工

| 层 | 职责 | 是否允许持有 Provider 协议 |
|----|------|------|
| 插件入口（`<Plugin>.swift`） | 解析 Provider、装配 Adapter/Observer/ViewModel | **允许** |
| `Capabilities/` | 声明最小能力边界；Adapter 收窄 Provider | **允许**（仅 Adapter import Provider 包） |
| `Observers/` | 订阅 Provider 事件 → 更新 ViewModel | 允许（Observer 需要完整事件面） |
| ViewModel / View / Service / Tool | 只依赖能力协议 | **禁止直接持有 Provider 协议** |

> **Observer 不迁移到能力协议**：Observer 需要订阅完整 Provider 事件面，
> 保留 Provider 类型；能力协议只服务业务层（ViewModel / View / Service / Tool）。

### 时序要求

先 `guard` 到具体 Provider → 创建 Adapter → 同步一次初始快照 → 再安装 Observer 监听。
与现有 Observer 生命周期一致；能力协议本身不负责事件订阅。

---

## 5. 规则清单

1. **收窄优先**：能力协议只声明实际用到的成员，禁止把 Provider 整个协议照抄一遍。
   对比 `ProjectProviding` 有 14 个成员，`GitDiffProjectCapability` 只收窄 3 个。
2. **类型策略**：能力协议优先使用无 Provider 依赖的类型
   （`URL`、`String`、`Bool`、插件自身模型）。
   当 Provider 的领域模型（如 `ProjectInfo`、`GitCommit`）是跨包共享值类型时，
   允许 Adapter 文件 import 并透传该模型；
   ViewModel 可 import Provider 包但**只引用模型类型，不引用 Provider 协议**。
3. **⚠️ 优先内联句柄类型**：Provider 的 `*ObserverHandle` 与 `*ProvidingEvent`
   不应直接出现在能力协议里 —— 它们会把 Provider 包重新泄漏给消费方。
   需在能力文件内**内联定义**自己的事件枚举与句柄协议：

   ```swift
   @MainActor
   protocol FooCapability: AnyObject {
       var value: Int { get }

       /// 插件自有事件，不泄漏 Provider 的事件类型
       enum ValueEvent { case changed(Int) }

       @discardableResult
       func addValueObserver(_ callback: @escaping (ValueEvent) -> Void) -> any ValueObserverHandle
   }

   protocol ValueObserverHandle: AnyObject { func cancel() }
   ```

   Adapter 内部负责把 `*ProvidingEvent` 映射为自有事件。
   若 Provider 事件类型已足够通用（如 `ProjectProvidingEvent`）且消费方确实需要其完整面，
   可暂时透传，但应在文件注释中说明理由，并在 Provider 事件面变化时同步检查。

4. **禁止循环**：Adapter 可依赖 `Provider*` 包；Provider 包**不得**反向依赖插件包。
5. **`@MainActor`**：能力协议与 Adapter 默认标注 `@MainActor`（GitOK Provider 均为主线程语义）。
   若 ViewModel 在 `Task { @MainActor in }` 跨闭包使用能力，能力协议需精化 `Sendable`。
6. **日志**：Adapter 构造失败 / Provider 缺失统一在插件入口用 `Self.logger.error` 记录，
   Adapter 内部不重复打日志。

---

## 6. 是否该建 Capability（判断标准）

**应当建**：
- View / ViewModel / Observer 直接持有 `any XxxProviding`
- 同一 Provider 在插件内有 2 处以上消费点
- 单元测试需要 mock 掉某个外部能力

**不必建**：
- 只有插件入口（`<Plugin>.swift`）消费 Provider —— 入口本就是组装层，直接 `resolveProvider` 即可
- 只有单个 Observer 消费、且仅转发一次事件

**不适用**：
- 插件本身是某个 Provider 的**实现者**（如 `PluginAgentLoop` 实现 `AgentLoopProviding`）。
  持有其他 Provider 属于实现层依赖，收窄会限制实现能力，不适用本机制。

---

## 7. 惰性解析场景

当 Provider 的注册时机**晚于**本插件的 `onBoot`（跨插件 boot 顺序不确定），
不要在插件入口把 Provider **快照**进 Adapter —— 快照会永久失效。

正确做法：让 Adapter 内部持**惰性解析闭包**，每次调用都重新 `resolveProvider`：

```swift
@MainActor
public final class XxxCapabilityAdapter: XxxCapability {
    private let resolve: @MainActor @Sendable () -> (any XxxProviding)?

    public init(resolve: @escaping @MainActor @Sendable () -> (any XxxProviding)?) {
        self.resolve = resolve
    }

    private var provider: (any XxxProviding)? { resolve() }
    public var value: Int { provider?.value ?? 0 }
}
```

这样「仓库不可用」的判断也要跟着改 —— 原代码靠**闭包返回 nil** 判断，
现在闭包被收进能力内部，应改判能力的 `isAvailable` / 空值语义。

GitOK 现有的 Scene 能力（`BannerSceneCapability` 等）均由入口在 `onBoot` 中
`guard` 到 `SceneProviding` 后构造，属于**快照式**；若调整 boot 顺序导致启动期
拿不到 Scene，需改用本节的惰性解析写法。

---

## 8. 渐进迁移

本规范**不要求**一次性改造全部插件。新增或重构插件时遵守；
既有插件在触及相关文件时顺手迁移即可。

**已完成迁移**（可作为参考实现）：

`PluginGitDiff`、`PluginCommitList`、`PluginCommitDetail`、`PluginBanner`、
`PluginIcon`、`PluginWorktreeClean`、`PluginGitConflictResolver`、`PluginGitBranchStatus`。

其余插件若仍存在「非入口文件直接依赖 `any *Providing`」，在触及时顺手迁移。

---

## 检查清单

新增/改造插件时，确认：

- [ ] View / ViewModel / Observer / Tool 不直接持有 `any *Providing`
- [ ] 能力协议只声明用到的成员，未照抄 Provider 全量接口
- [ ] 能力文件放在 `Capabilities/`（而非 `Providers/`）
- [ ] Adapter 在插件入口 `onBoot` 中创建并注入
- [ ] **Adapter 的生命周期有明确所有者**（入口持有，或被入口持有的 ViewModel 强引用）
- [ ] 优先内联自有事件枚举与句柄协议，未泄漏 Provider 的 `*ProvidingEvent` / `*ObserverHandle`
- [ ] 命名符合 `<Plugin前缀><Domain>Capability` / `Adapter`
- [ ] 可见性正确（内部消费 `internal`，跨插件共享下沉为 `Provider*` / `Kit*`）
- [ ] 能力协议与 Adapter 标注 `@MainActor`

---

## 相关规范

- [插件包目录结构规范](./plugin-package-structure.md) — `Sources/` 分层与包裹目录
- [插件国际化规范](./plugin-i18n-rules.md) — xcstrings 文件管理
- [日志记录规范](./logging-standards.md) — Swift 日志记录标准
- [Commit 规范](./commit-convention.md) — Git 提交信息约定