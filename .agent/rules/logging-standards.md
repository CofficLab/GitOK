# Lumi 插件日志记录规范

> 基于 Lumi 项目中 60+ 插件的实际代码分析总结，作为 GitOK 项目的日志记录参考标准。

---

## 1. 核心架构

### 1.1 日志协议：`SuperLog`

Lumi 使用统一的 `SuperLog` 协议为所有组件提供一致的日志格式：

```swift
public protocol SuperLog {
    static var emoji: String { get }   // 类型标识 emoji
    static var t: String { get }       // 完整日志前缀（含线程信息）
    static var author: String { get }  // 类型名称
}
```

**日志前缀格式**：
```
[QoS] | <emoji> <类名> | <消息>
```

**示例输出**：
```
[UI] | 📦 GitToolsPlugin          | ✅ GitToolsPlugin 初始化完成
[BG] | 🧵 BackgroundWorker        | Worker 已启动
```

### 1.2 QoS 线程标识

| Emoji | 标识 | QoS 级别 | 含义 |
|-------|------|----------|------|
| 🔥 | `[UI]` | UserInteractive | 主线程 |
| 2️⃣ | `[IN]` | UserInitiated | 用户发起 |
| 3️⃣ | `[DF]` | Default | 默认 |
| 4️⃣ | `[UT]` | Utility | 工具线程 |
| 5️⃣ | `[BG]` | Background | 后台线程 |

---

## 2. Logger 定义规范

### 2.1 插件主体 Logger（必须）

每个插件主体（Plugin Actor）必须定义一个静态 Logger：

```swift
actor MyPlugin: SuperPlugin, SuperLog {
    /// 插件专用 Logger
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.lumi",
        category: "plugin.my-plugin"
    )
    
    /// 日志标识 emoji
    nonisolated static let emoji = "📦"
    
    /// 是否启用详细日志
    nonisolated static let verbose = true
}
```

**命名规则**：
- **subsystem**：统一使用 `"com.coffic.lumi"`
- **category**：格式为 `"plugin.<插件名>"`，使用小写短横线命名法（kebab-case）

### 2.2 子组件 Logger（可选）

Service / ViewModel 等子组件可以拥有自己的 Logger：

```swift
// Service 层可以定义独立 Logger
private static let logger = Logger(
    subsystem: "com.coffic.lumi",
    category: "zhipu-quota-service"
)
```

或直接引用插件主体的 Logger（更常见）：

```swift
// ViewModel / View 中引用插件 Logger
MyPlugin.logger.info("\(self.t)操作描述")
```

### 2.3 统一前缀标识

每个类/结构体需要指定自己的 emoji：

| 层级 | 常见 Emoji | 示例 |
|------|-----------|------|
| Plugin 主体 | 📦 🐙 🧵 🎯 | 插件主入口 |
| Service 层 | 🔧 🔌 🌐 | 服务/网络层 |
| ViewModel 层 | 📊 📋 | 视图模型 |
| View 层 | 🖥️ 📺 | UI 层 |
| Tool 层 | 🛠️ ⚡ | Agent 工具 |
| Store 层 | 💾 | 数据持久化 |

---

## 3. Verbose 日志开关

### 3.1 定义 verbose

每个日志组件都应定义 `verbose` 开关：

```swift
nonisolated static let verbose = true   // 开发阶段
nonisolated static let verbose = false  // 生产/稳定阶段
```

### 3.2 使用 verbose 控制 info 日志

**info 级别日志**必须用 `verbose` 包裹：

```swift
if Self.verbose {
    Self.logger.info("\(self.t)开始执行操作")
}
```

### 3.3 error 日志不需要 verbose 包裹

**error 级别日志始终输出**，不做 verbose 控制：

```swift
do {
    let result = try await performOperation()
    if Self.verbose {
        Self.logger.info("\(self.t)操作成功: \(result)")
    }
} catch {
    // ❌ 不要用 verbose 包裹 error
    Self.logger.error("\(self.t)操作失败: \(error.localizedDescription)")
}
```

### 3.4 Verbose 层级继承

子组件可以引用父级 Plugin 的 verbose：

```swift
// 子组件继承插件的 verbose 设置
nonisolated static var verbose: Bool { MyPlugin.verbose }
```

---

## 4. 日志级别使用规范

| 级别 | 方法 | 用途 | 需要 verbose |
|------|------|------|-------------|
| **info** | `logger.info()` | 正常操作流程 | ✅ 需要 |
| **debug** | `logger.debug()` | 调试详情 | ✅ 需要 |
| **warning** | `logger.warning()` | 警告/异常但可恢复 | ❌ 不需要 |
| **error** | `logger.error()` | 操作失败/错误 | ❌ 不需要 |
| **fault** | `logger.fault()` | 严重故障 | ❌ 不需要 |

### 4.1 info — 常规流程追踪

```swift
// ✅ 生命周期
Self.logger.info("\(Self.t)✅ MyPlugin 初始化完成")
Self.logger.info("\(Self.t)📝 MyPlugin 已注册")
Self.logger.info("\(self.t)✅ MyPlugin 已启用")
Self.logger.info("\(self.t)⛔️ MyPlugin 已禁用")

// ✅ 操作流程
Self.logger.info("\(self.t)刷新镜像列表")
Self.logger.info("\(self.t)镜像列表刷新成功: \(fetched.count) 个镜像")
```

### 4.2 error — 错误记录

```swift
// ✅ 始终记录错误
Self.logger.error("\(self.t)刷新镜像列表失败: \(error.localizedDescription)")
Self.logger.error("\(self.t)文件读取失败: \(error)")
```

### 4.3 warning — 异常警告

```swift
// ✅ 不需要 verbose 控制
Self.logger.warning("\(Self.t)⚠️ 无法打开文件描述符监控目录：\(key)")
Self.logger.warning("\(Self.t)智谱 GLM 配额获取失败")
```

### 4.4 debug — 调试详情

```swift
// ✅ 用于临时调试，使用 verbose 控制
Self.logger.debug("\(Self.t)API 原始响应：\(payload)")
```

---

## 5. 日志消息格式规范

### 5.1 消息前缀 Emoji

在日志消息中使用 emoji 标注操作类型：

| Emoji | 含义 | 示例 |
|-------|------|------|
| ✅ | 成功 | `✅ 操作完成` |
| ❌ | 失败 | `❌ 操作失败` |
| ⚠️ | 警告 | `⚠️ 注意事项` |
| 📝 | 注册/记录 | `📝 已注册` |
| ⛔️ | 禁用/停止 | `⛔️ 已禁用` |
| 📂 | 读取/加载 | `📂 已加载数据` |
| 💾 | 保存/写入 | `💾 已保存配置` |
| 🔍 | 搜索/查询 | `🔍 开始搜索` |
| 🔄 | 刷新/同步 | `🔄 开始刷新` |
| ⬇️ | 下载/安装 | `⬇️ 开始安装` |
| ⬆️ | 上传/更新 | `⬆️ 开始更新` |
| 🗑️ | 删除 | `🗑️ 开始卸载` |
| 🚀 | 启动 | `🚀 Worker 已启动` |
| ⚙️ | 配置 | `⚙️ 配置已更新` |

### 5.2 消息模板

```swift
// 生命周期
"\(Self.t)✅ {PluginName} 初始化完成"
"\(Self.t)📝 {PluginName} 已注册"
"\(self.t)✅ {PluginName} 已启用"
"\(self.t)⛔️ {PluginName} 已禁用"

// 操作成功
"\(self.t){操作描述}成功: {详情}"
"\(self.t)✅ {操作描述}: {结果数据}"

// 操作失败
"\(self.t){操作描述}失败: \(error.localizedDescription)"

// View 生命周期
"\(self.t)📺 OnAppear"
"\(self.t)🚩 Init"
```

### 5.3 self.t vs Self.t

| 场景 | 使用方式 | 原因 |
|------|---------|------|
| 实例方法中 | `self.t` | 包含当前实例的类型信息 |
| 静态方法中 | `Self.t` | 在静态上下文中使用 |
| 跨类型引用 | `OtherType.t` | 引用其他类型的标识前缀 |

---

## 6. Logger 引用层级规范

### 6.1 推荐模式：统一引用 Plugin Logger

子组件（Tool、Service、ViewModel、View）统一引用所属插件的 Logger：

```swift
// Tool 中
struct MyTool: AgentTool, SuperLog {
    nonisolated static let emoji = "🛠️"
    nonisolated static let verbose = true
    
    func execute(arguments: [String: ToolArgument]) async throws -> String {
        if Self.verbose {
            MyPlugin.logger.info("\(Self.t)执行操作：\(args)")
        }
        
        do {
            // ...
        } catch {
            MyPlugin.logger.error("\(Self.t)执行失败：\(error.localizedDescription)")
        }
    }
}
```

```swift
// ViewModel 中
class MyViewModel: ObservableObject, SuperLog {
    nonisolated static let emoji = "📊"
    nonisolated static let verbose = true
    
    func loadData() async {
        if Self.verbose {
            MyPlugin.logger.info("\(self.t)开始加载数据")
        }
        // ...
    }
}
```

### 6.2 独立 Logger 模式

当 Service 层足够复杂或需要独立过滤时，可定义自己的 Logger：

```swift
private static let logger = Logger(
    subsystem: "com.coffic.lumi",
    category: "my-plugin.service-name"
)
```

---

## 7. 完整插件模板

```swift
import Foundation
import os
import MagicKit

/// MyPlugin - 插件描述
actor MyPlugin: SuperPlugin, SuperLog {
    // MARK: - Logger & Config
    
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.lumi",
        category: "plugin.my-plugin"
    )
    nonisolated static let emoji = "📦"
    nonisolated static let verbose = true
    
    // MARK: - Plugin Properties
    
    static let id: String = "MyPlugin"
    static let displayName: String = "My Plugin"
    static let description: String = "插件描述"
    static let iconName: String = "star.fill"
    static let isConfigurable: Bool = false
    static let enable: Bool = true
    static var order: Int { 100 }
    
    static let shared = MyPlugin()
    private init() {}
    
    // MARK: - Lifecycle
    
    nonisolated func onRegister() {
        if Self.verbose {
            Self.logger.info("\(Self.t)📝 MyPlugin 已注册")
        }
    }
    
    nonisolated func onEnable() {
        if Self.verbose {
            Self.logger.info("\(self.t)✅ MyPlugin 已启用")
        }
    }
    
    nonisolated func onDisable() {
        if Self.verbose {
            Self.logger.info("\(self.t)⛔️ MyPlugin 已禁用")
        }
    }
}
```

---

## 8. 日志查看方法

### Console.app
1. 过滤进程：`Lumi`
2. 搜索 subsystem：`com.coffic.lumi`
3. 搜索 category：`plugin.my-plugin`

### 终端命令
```bash
# 查看特定插件日志
log stream --predicate 'subsystem == "com.coffic.lumi" AND category == "plugin.my-plugin"' --level info

# 查看所有插件日志
log stream --predicate 'subsystem == "com.coffic.lumi" AND category BEGINSWITH "plugin"' --level info

# 只看错误日志
log stream --predicate 'subsystem == "com.coffic.lumi" AND category BEGINSWITH "plugin"' --level error
```

---

## 9. 注意事项

1. **错误日志永远不被 verbose 控制** — 确保线上问题可追踪
2. **避免在日志中输出敏感信息** — 不要记录 token、密码等
3. **日志粒度适中** — 关键操作记录，避免循环内高频日志
4. **中英文统一** — 建议日志消息统一使用中文（与 Lumi 现有风格一致）
5. **verbose 默认值** — 新插件建议设为 `false`，需要调试时临时开启
6. **不要使用 `print()`** — 统一使用 `os.Logger`，便于 Console.app 过滤
