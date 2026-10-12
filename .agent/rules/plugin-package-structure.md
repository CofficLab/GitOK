# 插件包目录结构规范

> 本规范定义了 GitOK 项目中 `Packages/` 下所有 SPM 插件包的内部目录结构标准。
> 基于项目中 70+ 插件包的实际分析，提炼出统一的最佳实践。
> 本规范聚焦 **SPM Package 级别**的目录组织；插件内部代码风格与文件内容规范参见 [插件结构标准](./plugin-structure-standards.md)。

---

## 1. SPM Package 目录结构

### 1.1 包级目录

每个 SPM Package 的根目录必须包含以下结构：

```
Packages/<PackageName>/
├── Package.swift              # 必需
├── README.md                  # 必需
├── Resources/                 # 可选，需要本地化或媒体资源时创建
│   └── *.xcstrings
├── Sources/
│   └── <PackageName>/         # 必需，包裹目录（与包名一致）
│       └── ...                # 源码文件与子目录
└── Tests/
    └── <PackageName>Tests/    # 必需，测试包裹目录
        └── ...                # 测试文件
```

### 1.2 必需项

| 项目 | 必需 | 说明 |
|------|:----:|------|
| `Package.swift` | ✅ | SPM 包声明文件 |
| `README.md` | ✅ | 包功能说明 |
| `Sources/<PackageName>/` | ✅ | 源码包裹目录，名称与包名一致 |
| `Tests/<PackageName>Tests/` | ✅ | 测试包裹目录，名称为包名 + Tests |
| `Resources/` | ⬚ | 仅当需要 `.xcstrings` 或媒体资源时创建 |

### 1.3 命名规范

| 范畴 | 规范 | 示例 |
|------|------|------|
| 插件包名 | `Plugin<Feature>` | `PluginCommitList` |
| 工具包名 | `Kit<Feature>` | `KitGit`、`KitOpenIn` |
| 提供者包名 | `Provider<Feature>` | `ProviderGit`、`ProviderProjects` |
| 工厂包名 | `Factory<App>` | `FactoryGitOK` |
| 测试目录 | `<PackageName>Tests` | `PluginCommitListTests` |

---

## 2. Sources 内部代码组织

### 2.1 核心规则：包裹目录

`Sources/` 下**必须**使用与包名一致的子目录作为命名空间，所有源码文件放入该目录中。

```
Sources/
  PluginCommitList/              ← ✅ 包裹目录
    CommitListPlugin.swift
    Views/

Sources/
  BannerPlugin.swift             ← ❌ 禁止：缺少包裹目录
```

### 2.2 Plugin 类包分层

#### 简单插件（≤ 3 个源文件）

入口文件直接放在包裹目录下：

```
Sources/
  PluginBanner/
    BannerPlugin.swift           # 入口
    Support/
      PluginLocalization.swift
```

#### 标准插件（4 ~ 10 个源文件）

按职责分层，仅创建实际需要的目录：

```
Sources/
  PluginCommitList/
    CommitListPlugin.swift       # 插件入口
    Capabilities/                # 能力声明
    Observers/                   # 事件订阅
    Support/                     # 本地化等
    Views/                       # SwiftUI 视图
```

#### 复杂插件（> 10 个源文件）

增加更多目录或对 Views 进行二级分组：

```
Sources/
  PluginProjects/
    ProjectsPlugin.swift
    Models/
    Observers/
    Providers/
    Services/
    Support/
    ViewModels/
    Views/
      List/
      Detail/
      Settings/
```

### 2.3 目录职责说明

| 目录 | 职责 | 存放内容 |
|------|------|---------|
| `Models/` | 数据模型 | struct / class / enum 数据定义 |
| `Observers/` | 事件订阅 | `*Observer`、`*Controller` 等监听类型 |
| `Support/` | 辅助 | `PluginLocalization.swift`、轻量扩展 |
| `ViewModels/` | 视图模型 | `@Observable` / `ObservableObject` 类 |
| `Views/` | 视图 | SwiftUI `View` 组件 |
| `Capabilities/` | 能力扩展 | 插件能力声明（如 `*Capability.swift`） |
| `Tools/` | Agent 工具 | `AgentTool` 实现 |
| `Middleware/` | 中间件 | 各类中间件 |
| `Providers/` | 协议实现 | `*Providing` 协议的具体实现 |
| `Helpers/` | 辅助函数 | 比 Support 更轻量的工具代码 |
| `Services/` | 业务服务 | 复杂业务逻辑、网络请求等 |

### 2.4 Kit / 框架类包分层

```
Sources/
  KitGit/
    Contracts/                   # 公共协议
    Core/                        # 核心实现
    Support/                     # 辅助代码
```

### 2.5 Provider 类包分层

Provider 包通常结构最简：

```
Sources/
  ProviderGit/
    GitProviding.swift
    DefaultGitProvider.swift
    Models/
```

当文件较多时可按 `Contracts/` + `Core/` 分层。

---

## 3. Views 二级分组规则

当 `Views/` 目录下文件 **超过 5 个** 时，应按功能模块拆分子目录：

```
Views/
  List/                          # 列表相关
    ListView.swift
    ListEmptyView.swift
    ItemView.swift
  Detail/                        # 详情相关
    DetailView.swift
    InfoView.swift
```

**判断标准**：
- ≤ 5 个视图文件 → 平铺在 `Views/` 下
- \> 5 个视图文件 → 按功能分组为子目录
- 每个子目录至少 2 个文件

---

## 4. Tests 组织规范

### 4.1 目录结构

所有测试使用包裹目录，放在 `Tests/<PackageName>Tests/` 下：

```
Tests/
  PluginCommitListTests/         ← ✅ 包裹目录
    CommitListPluginTests.swift
    CommitGraphViewTests.swift

Tests/
  SomeTests.swift                ← ❌ 禁止：缺少包裹目录
```

### 4.2 文件命名

| 项 | 规范 | 示例 |
|----|------|------|
| 测试目录 | `<PackageName>Tests` | `PluginCommitListTests` |
| 测试文件 | `<SourceFileName>Tests.swift` | `CommitGraphViewTests.swift` |

测试文件与源文件 **一一对应**。

### 4.3 测试框架

新代码优先使用 **Swift Testing**（`import Testing`）：

```swift
import Testing
@testable import PluginCommitList

@Suite("CommitListPlugin")
struct CommitListPluginTests {
    @Test("registers commit list capability")
    func registersCapability() {
        // ...
    }
}
```

遗留的 **XCTest**（`import XCTest`）可保留，不强制迁移。

---

## 5. Package.swift 配置

### 5.1 测试 target

必须声明 `testTarget` 并正确设置依赖：

```swift
.testTarget(
    name: "PluginCommitListTests",
    dependencies: ["PluginCommitList"]
)
```

### 5.2 资源配置

需要本地化资源时：

```swift
.target(
    name: "PluginCommitList",
    dependencies: [...],
    resources: [.process("Resources")]
)
```

不需要资源时省略 `resources` 参数，且 **不要** 创建空的 `Resources/` 目录。

---

## 6. 最佳实践

### ✅ 推荐

- 只有 2 ~ 3 个文件时，直接放包裹目录下，不强行建子目录
- 文件名与主类型名一致（`CommitListPlugin.swift` → `struct CommitListPlugin`）
- 每个视图单独一个文件，参照 [视图拆分规范](./views-should-be-separated.md)
- 目录嵌套不超过 3 层
- 新插件包统一使用包裹目录结构

### ❌ 避免

- 无脑为每个目录分类都创建子目录
- 创建空的占位目录
- 在包裹目录外直接放源码文件

---

## 7. 实际参考

| 包 | 复杂度 | 分层方式 |
|----|--------|---------|
| `PluginCommitList` | 标准 | Capabilities / Observers / Support / Views |
| `PluginProjects` | 复杂 | Models / Observers / Providers / Services / Support / ViewModels / Views |
| `KitGit` | 框架 | 按架构分层 |
| `ProviderGit` | 简单 | 平铺 + Models/ |
| `PluginBanner` | 极简 | 入口 + Support/ |

---

## 相关规范

- [插件结构标准](./plugin-structure-standards.md) — 插件内部代码风格与文件内容规范
- [日志记录规范](./logging-standards.md) — Swift 日志记录标准
- [插件国际化规范](./plugin-i18n-rules.md) — xcstrings 文件管理
