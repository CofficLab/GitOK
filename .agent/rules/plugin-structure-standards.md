# Lumi 插件目录结构规范

> 基于 Lumi 项目中 60+ 插件的实际代码分析总结，作为 GitOK 项目的插件目录结构参考标准。

---

## 1. 标准目录结构

### 1.1 完整结构模板

```
PluginName/
├── PluginNamePlugin.swift          # 插件主体文件（必需）
├── PluginName.xcstrings             # 多语言资源文件（必需）
├── Models/                          # 数据模型（可选）
│   ├── MyModel.swift
│   └── ...
├── Services/                        # 服务层（可选）
│   ├── MyService.swift
│   └── ...
├── ViewModels/                      # 视图模型（可选）
│   ├── MyViewModel.swift
│   └── ...
├── Views/                           # 视图层（可选）
│   ├── MyView.swift
│   └── ...
├── Tools/                           # Agent 工具（可选）
│   ├── MyTool.swift
│   └── ...
├── Middleware/                      # 中间件（可选）
│   ├── MyMiddleware.swift
│   └── ...
├── Utils/                           # 工具类（可选）
│   ├── Extensions/
│   │   └── String+Extensions.swift
│   └── Helpers/
│       └── Formatter.swift
├── Store/                           # 数据存储层（可选）
│   ├── MyStore.swift
│   └── ...
├── Services/                        # 服务层（可选）
│   └── ...
├── Protocols/                       # 协议定义（可选）
│   └── MyProtocol.swift
└── Tests/                           # 单元测试（可选）
    └── MyPluginTests.swift
```

### 1.2 必需文件

| 文件 | 必需 | 说明 |
|------|------|------|
| `PluginNamePlugin.swift` | ✅ | 插件主体，遵循 `SuperPlugin` 协议 |
| `PluginName.xcstrings` | ✅ | 多语言资源文件 |

### 1.3 可选目录

| 目录 | 用途 | 示例 |
|------|------|------|
| `Models/` | 数据模型 | `BrewPackage.swift` |
| `Services/` | 业务逻辑服务 | `GitService.swift` |
| `ViewModels/` | SwiftUI ViewModel | `BrewManagerViewModel.swift` |
| `Views/` | UI 视图 | `DockerImagesView.swift` |
| `Tools/` | Agent 工具 | `ShellTool.swift` |
| `Middleware/` | 中间件 | `RAGSendMiddleware.swift` |
| `Utils/` | 工具类/扩展 | `GitUtils.swift` |
| `Store/` | 数据存储 | `RecentProjectsStore.swift` |

---

## 2. 文件命名规范

### 2.1 插件主体文件

```
PluginNamePlugin.swift
```

**示例**：
- `GitToolsPlugin.swift`
- `BrewManagerPlugin.swift`
- `RecentProjectsPlugin.swift`

### 2.2 多语言文件

```
PluginName.xcstrings
```

**示例**：
- `GitTools.xcstrings`
- `BrewManager.xcstrings`
- `RecentProjects.xcstrings`

### 2.3 视图文件

```
[Component]View.swift
```

**示例**：
- `DockerImagesView.swift`
- `BrewManagerView.swift`
- `RAGSettingsView.swift`

### 2.4 ViewModel 文件

```
[Feature]ViewModel.swift
```

**示例**：
- `BrewManagerViewModel.swift`
- `ChatTimelineViewModel.swift`
- `MemoryManagerViewModel.swift`

### 2.5 服务文件

```
[Feature]Service.swift
```

**示例**：
- `GitService.swift`
- `GitHubAPIService.swift`
- `ClipboardMonitor.swift`

### 2.6 模型文件

```
[Feature][Type].swift
```

**示例**：
- `BrewPackage.swift`
- `ProjectBranchAutoPushConfig.swift`
- `GitStatus.swift`

### 2.7 工具文件

```
[Action]Tool.swift
```

**示例**：
- `ShellTool.swift`
- `ReadFileTool.swift`
- `GrepTool.swift`

---

## 3. 目录层级规则

### 3.1 扁平 vs 层级

| 场景 | 规则 | 示例 |
|------|------|------|
| 简单插件（≤3 文件） | 扁平结构 | 直接放在插件根目录 |
| 中等插件（4-10 文件） | 单层目录 | 使用 `Views/`、`Services/` 等 |
| 复杂插件（>10 文件） | 多层目录 | `Views/SubFolder/` |
| 工具集合 | 集中管理 | 所有工具放在 `Tools/` |
| View 组件过多 | 按功能分组 | `Views/Settings/`、`Views/Status/` |

### 3.2 常见分组方式

#### 3.2.1 View 分组

```
Views/
├── Config/                 # 配置相关视图
│   ├── SettingsView.swift
│   └── ConfigRowView.swift
├── Status/                 # 状态栏视图
│   └── StatusBarView.swift
└── Details/                # 详情视图
    ├── DetailView.swift
    └── InfoView.swift
```

#### 3.2.2 Tool 分组

```
Tools/
├── Git/                     # Git 相关工具
│   ├── GitStatusTool.swift
│   ├── GitDiffTool.swift
│   └── GitLogTool.swift
└── GitHub/                  # GitHub 相关工具
    ├── GitHubRepoInfoTool.swift
    └── GitHubIssueListTool.swift
```

#### 3.2.3 Service 分组

```
Services/
├── Core/                    # 核心服务
│   └── LLMService.swift
└── Network/                 # 网络服务
    ├── GitHubAPIService.swift
    └── NetworkMonitorService.swift
```

---

## 4. 文件内容规范

### 4.1 插件主体文件 (PluginNamePlugin.swift)

```swift
import Foundation
import MagicKit
import os
import SwiftUI

/// [插件描述]
actor PluginNamePlugin: SuperPlugin, SuperLog {
    // MARK: - Logger & Config

    /// 插件专用 Logger
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok",
        category: "plugin.plugin-name"
    )

    /// 日志标识 emoji
    nonisolated static let emoji = "📦"

    /// 是否启用详细日志
    nonisolated static let verbose = false

    // MARK: - Plugin Properties

    static let id: String = "PluginName"
    static let displayName: String = String(localized: "Plugin Name", table: "PluginName")
    static let description: String = String(localized: "Plugin description", table: "PluginName")
    static let iconName: String = "star.fill"
    static let isConfigurable: Bool = false
    static let enable: Bool = true
    static var order: Int { 100 }

    static let shared = PluginNamePlugin()

    private init() {}

    // MARK: - Lifecycle

    nonisolated func onRegister() {
        if Self.verbose {
            Self.logger.info("\(Self.t)📝 PluginName 已注册")
        }
    }

    nonisolated func onEnable() {
        if Self.verbose {
            Self.logger.info("\(self.t)✅ PluginName 已启用")
        }
    }

    nonisolated func onDisable() {
        if Self.verbose {
            Self.logger.info("\(self.t)⛔️ PluginName 已禁用")
        }
    }

    // MARK: - Views

    @MainActor
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        // 返回根视图（可选）
    }

    // MARK: - Agent Tools

    @MainActor
    func agentToolFactories() -> [AnyAgentToolFactory] {
        // 返回工具工厂（可选）
        []
    }
}
```

### 4.2 View 文件

```swift
import SwiftUI
import MagicKit

/// [视图描述]
struct MyView: View, SuperLog {
    // MARK: - Logger & Config

    nonisolated static let emoji = "🖥️"
    nonisolated static let verbose = false

    // MARK: - Properties

    // ...

    // MARK: - Body

    var body: some View {
        // ...
    }
}

#Preview("MyView") {
    MyView()
        .frame(width: 600, height: 400)
}
```

### 4.3 Tool 文件

```swift
import Foundation
import MagicKit

/// [工具描述]
struct MyTool: AgentTool, SuperLog {
    nonisolated static let emoji = "🛠️"
    nonisolated static let verbose = true

    let name = "my_tool"
    let description = "Tool description"

    var inputSchema: [String: Any] {
        // ...
    }

    func permissionRiskLevel(arguments: [String: ToolArgument]) -> CommandRiskLevel {
        // ...
    }

    func execute(arguments: [String: ToolArgument]) async throws -> String {
        if Self.verbose {
            MyPlugin.logger.info("\(Self.t)执行操作")
        }

        do {
            // 执行逻辑
            return "result"
        } catch {
            MyPlugin.logger.error("\(Self.t)操作失败: \(error.localizedDescription)")
            throw error
        }
    }
}
```

### 4.4 Service 文件

```swift
import Foundation
import MagicKit

/// [服务描述]
class MyService: SuperService, SuperLog {
    nonisolated static let emoji = "🔧"
    nonisolated static let verbose = false

    static let shared = MyService()

    private init() {
        if Self.verbose {
            MyPlugin.logger.info("\(Self.t)初始化完成")
        }
    }

    // MARK: - Methods

    func doSomething() async throws {
        // ...
    }
}
```

### 4.5 Model 文件

```swift
import Foundation
import SwiftData

/// [模型描述]
@Model
class MyModel: Codable, Identifiable {
    let id: String
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

---

## 5. 目录组织最佳实践

### 5.1 单一职责

- **PluginNamePlugin.swift**: 仅包含插件主体逻辑
- **Services/**: 仅包含业务逻辑服务
- **ViewModels/**: 仅包含视图模型
- **Views/**: 仅包含 UI 组件

### 5.2 依赖方向

```
Views
  ↓ 依赖
ViewModels
  ↓ 依赖
Services/Models
  ↓ 依赖
PluginNamePlugin
```

### 5.3 共享资源

- **常量/配置**: 放在 PluginNamePlugin.swift 或独立的 `Config.swift`
- **扩展方法**: 放在 `Utils/Extensions/`
- **公共模型**: 放在 `Models/`

---

## 6. 示例：完整插件结构

### 6.1 简单插件（GitTools）

```
GitToolsPlugin/
├── GitToolsPlugin.swift
├── GitTools.xcstrings
├── Services/
│   └── GitService.swift
└── Tools/
    ├── GitStatusTool.swift
    ├── GitDiffTool.swift
    └── GitLogTool.swift
```

### 6.2 中等插件（BrewManager）

```
BrewManagerPlugin/
├── BrewManagerPlugin.swift
├── BrewManager.xcstrings
├── Models/
│   └── BrewPackage.swift
├── Services/
│   └── BrewService.swift
├── ViewModels/
│   └── BrewManagerViewModel.swift
└── Views/
    └── BrewManagerView.swift
```

### 6.3 复杂插件（RAG）

```
RAGPlugin/
├── RAGPlugin.swift
├── RAGIndexEvents.swift
├── RAG.xcstrings
├── Models/
│   ├── RAGConfig.swift
│   └── RAGDocument.swift
├── Services/
│   ├── RAGService.swift
│   ├── RAGIndexer.swift
│   ├── RAGRetriever.swift
│   ├── RAGChunker.swift
│   ├── RAGContextBuilder.swift
│   └── providers/
│       ├── EmbeddingProvider.swift
│       └── VectorStoreProvider.swift
├── Middleware/
│   └── RAGSendMiddleware.swift
├── Utils/
│   ├── RAGTextUtils.swift
│   ├── RAGMathUtils.swift
│   ├── RAGPathUtils.swift
│   ├── RAGFileScanner.swift
│   └── RAGUtils.swift
└── Views/
    ├── RAGSettingsView.swift
    ├── RAGStatusBarView.swift
    └── RAGAutoIndexOverlay.swift
```

---

## 7. 注意事项

1. **文件名与类名保持一致** - 避免混淆
2. **不要过度嵌套** - 一般不超过 3 层
3. **相关文件放在一起** - 方便维护
4. **使用 MARK 注释** - 组织代码结构
5. **遵循命名约定** - PascalCase 用于类型，camelCase 用于变量/方法
6. **添加文件头注释** - 说明文件用途
7. **保持目录扁平** - 除非有明确的分组需求

---

## 8. 快速参考

### 8.1 最小结构

```
MyPlugin/
├── MyPluginPlugin.swift
└── MyPlugin.xcstrings
```

### 8.2 标准结构

```
MyPlugin/
├── MyPluginPlugin.swift
├── MyPlugin.xcstrings
├── Services/
│   └── MyService.swift
└── Views/
    └── MyView.swift
```

### 8.3 完整结构

```
MyPlugin/
├── MyPluginPlugin.swift
├── MyPlugin.xcstrings
├── Models/
│   └── MyModel.swift
├── Services/
│   └── MyService.swift
├── ViewModels/
│   └── MyViewModel.swift
├── Views/
│   └── MyView.swift
├── Tools/
│   └── MyTool.swift
└── Utils/
    └── MyExtensions.swift
```