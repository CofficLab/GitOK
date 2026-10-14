# 插件 Capabilities 能力边界规范

> 本规范定义 GitOK 插件如何声明自己**消费外部能力**的最小边界。
> 与兄弟项目 Lumi / Cisum 的同名机制保持一致，核心目的：让
> View / ViewModel / Service / Tool 不再直接依赖 `any *Providing` 宽接口。

---

## 核心原则

**插件依赖的是「自己声明的窄能力」，不是「内核的宽 Provider」。**

一个插件对外界（内核 Provider、其他插件的 Provider）的所有依赖，都应收敛到本插件
`Capabilities/` 目录下的 `protocol XxxCapability` + `XxxCapabilityAdapter`。
View / ViewModel / Service / Tool 只面向该窄协议编程。

> 外部能力进入插件的唯一入口是**能力协议 + Adapter**（依赖收窄），
> 外部状态进入插件的唯一入口是**Observer**（状态收窄）。两者互补、不冲突：
> Observer 负责「状态怎么进来」，Capabilities 负责「接口怎么收窄」。

---

## 1. 目录位置

GitOK 的 SPM 包**统一使用包裹目录**，因此位置固定：

```
Sources/<PackageName>/Capabilities/<XxxCapability>.swift
```

目录与 `Observers/`、`ViewModels/`、`Views/`、`Providers/` 平级。

---

## 2. 与 `Providers/` 的区别（关键，别混淆）

GitOK 中两个目录方向**相反**：

| 目录 | 方向 | 内容 | 例 |
|------|------|------|------|
| `Providers/` | **生产**：本插件向外**提供**能力 | 实现内核的 `*Providing` 协议 | `PluginProjects/Providers/ProjectSidebarProviding.swift` |
| `Capabilities/` | **消费**：本插件向**内**索取能力 | 声明本插件**需要的**窄接口 + Adapter | `PluginProjects/Capabilities/ProjectSidebarCapability.swift` |

一句话：`Providers/` 是我给别人什么，`Capabilities/` 是我需要什么。

---

## 3. 标准写法

以 `PluginProjects` 的项目能力为参考实现：

```swift
import Foundation
import ProviderProjects

/// 项目列表侧边栏所需的最小能力。
///
/// 插件入口在装配阶段用 `ProjectProviding` 适配本协议；视图、Picker 与
/// 协调器只依赖它，不再直接持有 24 个成员的项目 Provider。
@MainActor
protocol ProjectSidebarCapability: AnyObject {
    var projects: [Project] { get }
    var currentProject: Project? { get }

    func addProject(at url: URL)
    func openProject(at url: URL)
    func setCurrentProject(id: UUID?)

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将 `ProjectProviding` 收窄成侧边栏所需的能力。
@MainActor
final class ProjectSidebarCapabilityAdapter: ProjectSidebarCapability {
    private let provider: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.provider = projects
    }

    var projects: [Project] { provider.projects }
    var currentProject: Project? { provider.currentProject }

    func addProject(at url: URL) { provider.addProject(at: url) }
    func openProject(at url: URL) { provider.openProject(at: url) }
    func setCurrentProject(id: UUID?) { provider.setCurrentProject(id: id) }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        provider.addObserver(callback)
    }
}
```

### 命名规范

| 角色 | 命名 |
|------|------|
| 协议 | `<插件前缀><Domain>Capability`，如 `ProjectSidebarCapability`、`BannerSceneCapability` |
| 适配器 | 协议名 + `Adapter`，如 `ProjectSidebarCapabilityAdapter` |
| 事件枚举 | `<Domain>Event`，如 `ProjectSidebarEvent` |
| 观察句柄 | `<Domain>ObserverHandle`，如 `ProjectSidebarObserverHandle` |

> 多个能力共用同一 Provider 时，前缀区分用途而非 Provider 本身
> （如 `ProjectSidebarCapability` 与 `ProjectCloneCapability`）。
> 插件前缀可省略当包名已隐含唯一性时（如 `Banner/Capabilities/BannerSceneCapability.swift`）。

### 可见性

| 场景 | 修饰符 |
|------|--------|
| 能力仅本插件内部消费 | `internal`（默认，不写修饰符） |
| 能力需被本包 `Tests` 使用 | `public` |
| 能力需被**其他插件**消费 | 不属于本机制 —— 应下沉为 `Provider*` / `Kit*` 包 |

> GitOK 的插件包默认只被 `FactoryGitOK` 通过 `resolveProvider` / `registerProvider`
> 使用，因此绝大多数能力保持 `internal` 即可。若 `public init` 暴露了能力参数，
> 才需要把该能力提为 `public`。

---

## 4. 装配规则

Adapter 一律在插件入口的 `onBoot(kernel:)` 中创建并注入 ViewModel / View / Service。

```swift
@MainActor
public final class FooPlugin: SuperPlugin {
    private var viewModel: FooViewModel?
    private var capability: FooProjectCapability?

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered")
            return
        }
        let capability = FooProjectCapabilityAdapter(projects: projects)
        self.capability = capability
        let viewModel = FooViewModel(capability: capability)
        self.viewModel = viewModel
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        viewModel = nil
        capability = nil
    }
}
```

### ⚠️ 生命周期陷阱：Adapter 无人持有会静默失效

如果 Adapter 只是**临时创建后直接注入**，且没有任何强引用持有它，
Adapter 会随 `onBoot` 返回立即释放，消费方的 `weak` 全部落空（功能静默失效）。

```swift
// ❌ 错误：Adapter 无人持有；如果注入方用 weak 接收，功能永远不生效
let viewModel = MyViewModel(capability: MyCapabilityAdapter(projects: projects))

// ✅ 正确：入口显式强持有 Adapter，并在 onShutdown 释放
private var capability: MyProjectCapability?
...
let capability = MyCapabilityAdapter(projects: projects)
self.capability = capability
let viewModel = MyViewModel(capability: capability)
```

判断标准：**如果消费方不持有 Adapter（或持有为 `weak`），入口必须持有。**
若消费方以强引用存进 ViewModel 且 ViewModel 被入口持有，Adapter 随 ViewModel 存活，可不强持。

### 与 Observer 的分工

| 层 | 职责 | 是否允许持有 Provider 协议 |
|----|------|------|
| 插件入口（`XxxPlugin.swift`） | 解析 Provider、装配 Adapter/Observer/ViewModel | **允许** |
| `Capabilities/` | 声明最小能力边界；Adapter 收窄 Provider | **允许**（仅 Adapter import Provider 包） |
| `Providers/` | 本插件实现内核 `*Providing` 协议 | **允许**（实现层依赖） |
| `Observers/` | 订阅 Provider 事件 → 更新 ViewModel | **允许**（Observer 需要完整事件面） |
| ViewModel / View / Service / Tool | 只依赖能力协议 | **禁止直接持有 Provider 协议** |

> **Observer 不迁移到能力协议**：Observer 需要订阅完整 Provider 事件面，
> 保留 Provider 类型；能力协议只服务业务层（ViewModel / View / Service / Tool）。
> 这是 GitOK 与 Cisum 规则的差异点：Cisum 的检查清单把 Observer 也列入禁止项，
> 但其 `Observers/` 目录同样允许持有 Provider——以本表的分工为准。

### 时序要求

先 `guard` 到具体 Provider → 创建 Adapter → 同步一次初始快照 → 再安装 Observer 监听。
与现有 Observer 生命周期一致；能力协议本身不负责事件订阅。

---

## 5. 规则清单

1. **收窄优先**：能力协议只声明实际用到的成员，禁止把 Provider 整个协议照抄一遍。
   对比 `ProjectProviding` 有 24 个成员，`ProjectSidebarCapability` 只收窄 11 个。

2. **⚠️ 不泄漏句柄类型（存量豁免）**：Provider 的 `*ObserverHandle` 与 `*ProvidingEvent`
   不应直接出现在能力协议里 —— 它们会把 Provider 包重新泄漏给消费方。
   理想写法是在能力文件内**内联定义**自己的事件枚举与句柄协议：

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

   **GitOK 现状**：28 个存量 Adapter 全部采用透传写法 ——
   19 个场景能力透传 `WorkspaceSceneEvent` / `WorkspaceSceneObserverHandle`，
   9 个项目能力透传 `ProjectProvidingEvent` / `ProjectProvidingObserverHandle`。
   属于**已记录的存量豁免**，不算违规。
   但**新建的能力不再豁免**：新增能力时若涉及事件订阅，应内联自有事件枚举；
   若因 Provider 事件面过宽暂时透传，必须在文件注释中写明理由。

3. **禁止循环**：Adapter 可依赖 `Provider*` 包；Provider 包**不得**反向依赖插件包。
   Adapter 持有 Provider 时 GitOK 当前统一用**强引用**（`private let`）：
   插件入口在 `onShutdown` 已显式注销并释放，Adapter 生命周期与插件一致。

4. **`@MainActor`**：能力协议与 Adapter 默认标注 `@MainActor`（GitOK Provider 均为主线程语义）。
   若 ViewModel 在 `Task { @MainActor in }` 跨闭包使用能力，能力协议需精化 `Sendable`。

5. **日志**：Adapter 构造失败 / Provider 缺失统一在插件入口用 `Self.logger.error` 记录，
   Adapter 内部不重复打日志。

---

## 6. 是否该建 Capability（判断标准）

**应当建**：
- View / ViewModel / Service / Tool 直接持有 `any XxxProviding`（**无论成员多少**——消费面小不等于可以绕过边界）
- 同一 Provider 在插件内有 2 处以上消费点
- 入口注入的多个闭包各自 `resolveProvider` 同一个 Provider（收敛为一个能力，解析与降级语义只留一份）
- 单元测试需要 mock 掉某个外部能力

**不必建**（豁免项必须在代码中写注释说明理由）：
- 只有插件入口（`XxxPlugin.swift`）消费 Provider —— 入口本就是组装层，直接 `resolveProvider` 即可
- `Providers/` 生产目录内的文件 —— 那是本插件**实现** Provider 的地方及其基础设施依赖
- `Observers/` 下的文件 —— 见第 4 节分工表
- 一次性同步读取的闭包、纯诊断快照 —— 不订阅、不持有、不重试
- 组装层 View 中「`resolveProvider` 后立刻包成 Adapter」的调用 —— View 在此角色等同入口，
  但必须在调用点注释说明组装层身份

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

GitOK 现有的场景能力（`XxxSceneCapability`）由入口在 `onBoot` 中
`guard` 到 `WorkspaceSceneProviding` 后构造，属于**快照式**；
若调整 boot 顺序导致启动期拿不到 Scene，需改用本节的惰性解析写法。

---

## 8. 迁移状态与验证

### 已完成迁移（可作为参考实现）

| 插件 | 参考点 |
|------|---------|
| `PluginRootView` | 双能力收窄（`RootViewProjectCapability` + `RootViewCloneCapability`），可选 Provider 在 Adapter 内降级 |
| `PluginProjects` | 多能力拆分（`ProjectSidebarCapability` / `ProjectCloneCapability` / `GitRemoteCapability`）+ 状态机抽离可测 |
| `PluginBanner`、`PluginIcon` | `XxxProjectCapability` 由 `public` ViewModel 暴露，故提为 `public` |

### 存量豁免（已记录，不算违规）

扫描命令的输出需要按下列四类逐条判定，**只有第 1 类是真违规**：

1. **待迁移的真实违规（26 个包，基线 2026-10-14）** —— View / ViewModel 直接持有
   `any ProjectProviding` / `any GitProviding` 等，绝大多数是「status tile」形态
   （`GitLFSStatusTile`、`SubmoduleStatusTile` 等），单个成员消费。
   迁移优先级按聚集度：

   | 插件 | 处数 | 说明 |
   |------|------|------|
   | `PluginGitBranchStatus` | 4 | `BranchStatusTile` / `BranchPickerView` 等 4 个视图同时吃 Project + Git |
   | `PluginGitConflictResolver` | 3 | 同上形态 |
   | `PluginWorktreeClean` | 3 | 额外吃 `ProjectReadmeProviding`、`CollaboratorProviding` |
   | `PluginCommitDetail` | 4 | ViewModel 层持有 `GitProviding` |
   | 其余 22 个包 | 各 1–2 | status tile / 单视图，模式高度一致，宜批量处理 |

2. **28 个存量 Adapter 透传 `*ProvidingEvent` / `*ObserverHandle`** —— 见第 5 节第 2 条。
   这些文件位于 `Capabilities/`，不属于本节统计范围。
3. **`Observers/` 下的文件持有 Provider** —— 见第 4 节分工表，同样允许。
4. **单成员 Provider 与实现层**：
   - `ProjectManager.swift` 等 `*Manager.swift` 实现 `*Providing` 协议，属实现层依赖。
   - **`ToastProviding` / `ThemeProviding` / `DocsViewProviding` 等在 View 层直接注入** ——
     它们成员极少且无状态，收窄后与原接口等价，收益不抵改动成本。
     存量保持现状，新增消费点时再考虑收窄。

> 已完成的迁移：`PluginProjects`（`ProjectSidebarCapability` 等三件套）、
> `PluginRootView`（`RootViewProjectCapability` + `RootViewCloneCapability`）。
> 二者当前仍会被扫描命中，原因是 View 层保留 `ToastProviding`
> （属第 4 类）与入口文件的 `resolveProvider`（属豁免）。

### 验证扫描命令

```bash
cd Packages && for p in Plugin*/ Kit*/; do n=$(basename $p); [ -d "$p/Sources" ] || continue
  files=$(grep -rlE "any [A-Z][A-Za-z]*Providing" "$p/Sources" --include="*.swift" 2>/dev/null \
    | grep -vE "/\.build/" \
    | grep -vE "/Capabilities/|/Observers/|/Providers/|/Services/" \
    | grep -vE "Plugin\.swift$|Manager\.swift$")
  c=$(echo "$files" | grep -c .)
  [ "$c" != "0" ] && { echo "-- $n ($c)"; echo "$files" | sed "s|$p/Sources/||"; }
done
```

> **两个容易踩的坑**：
> 1. 必须排除 `/.build/` —— 各包的 checkout 目录含上游 Provider 源码，会产生大量假阳性。
> 2. 用宽模式 `any XxxProviding`，不要用 `(any ...` —— 带括号的窄模式会漏掉
>    `init(projects: any ProjectProviding)` 这类无括号签名。
>
> **当前基线（2026-10-14）**：按上述口径实测，业务层（Views / ViewModels /
> Observers / Support / Tools）持有宽 Provider 的包共 **26 个**，即第 1 类。
> `PluginProjects`、`PluginRootView` 已迁移完毕，其剩余命中全部落在第 3、4 类。

### 回归

```bash
cd Packages/PluginProjects && swift test 2>&1 | grep -E "✘|error:|Test run with" | tail -3
```

---

## 检查清单

新增/改造插件时，确认：

- [ ] View / ViewModel / Service / Tool 不直接持有 `any *Providing`
- [ ] `Observers/`、`Providers/`、插件入口不属于本规范的管辖范围
- [ ] 能力协议只声明用到的成员，未照抄 Provider 全量接口
- [ ] 未泄漏 Provider 的 `*ObserverHandle` 与事件类型（存量透传已豁免，新代码不豁免）
- [ ] 能力文件放在 `Capabilities/`（而非 `Providers/`）
- [ ] Adapter 在插件入口 `onBoot` 中创建并注入
- [ ] **Adapter 的生命周期有明确所有者**（入口持有，或被入口持有的 ViewModel 强引用）
- [ ] 命名符合 `<插件前缀><Domain>Capability` / `Adapter`
- [ ] 可见性正确（内部消费 `internal`，跨插件共享下沉为 `Provider*` / `Kit*`）
- [ ] 能力协议与 Adapter 标注 `@MainActor`
- [ ] 收窄后保留「Provider 缺失时的降级语义」—— 原代码靠 `provider == nil` 判断可用性时，
      要在能力上以 `isAvailable` / 空值语义显式承载，避免 UI 在启动早期误闪

---

## 相关规范

- [插件包目录结构规范](./plugin-package-structure.md) — `Sources/` 分层与包裹目录
- [插件国际化规范](./plugin-i18n-rules.md) — xcstrings 文件管理
- [Lumi 插件日志记录规范](./logging-standards.md) — Swift 日志记录标准
- [Commit 规范](./commit-convention.md) — Git 提交信息约定
