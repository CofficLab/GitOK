# 插件开发快速入门

这是一个快速指南，帮助您在 10 分钟内创建第一个 GitOK 插件。

## 步骤 1：创建插件类

在 `Plugins` 目录下创建新文件夹和插件文件：

```tree
Plugins/
└── MyFeature/
    └── MyFeaturePlugin.swift
```

## 步骤 2：实现插件协议

```swift
import MagicKit
import OSLog
import SwiftUI

class MyFeaturePlugin: SuperPlugin, PluginRegistrant, SuperLog {
    // MARK: - 插件元数据
    nonisolated static let emoji = "🌟"
    nonisolated static let verbose = true

    static let label = "MyFeature"
    static var id: String = "MyFeature"
    static var displayName: String = "我的功能"
    static var description: String = "这是一个示例插件"
    static var iconName: String = "star.fill"
    static var isConfigurable: Bool = false
    static let enable = true
    static let shared = MyFeaturePlugin()

    var isTab: Bool = false  // 是否创建标签页

    private init() {}
}
```

## 步骤 3：注册插件

```swift
extension MyFeaturePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            await PluginRegistry.shared.register(id: "MyFeature", order: 50) {
                MyFeaturePlugin.shared
            }
        }
    }
}
```

## 步骤 4：添加视图

### 方案 A：添加工具栏按钮

```swift
extension MyFeaturePlugin {
    func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(
            Button(action: {
                print("按钮被点击")
            }) {
                Image(systemName: "star")
            }
        )
    }
}
```

### 方案 B：添加侧边栏列表

```swift
extension MyFeaturePlugin {
    func addListView(tab: String, project: Project?) -> AnyView? {
        // 只在 Git 标签页显示
        guard tab == GitPlugin.label else { return nil }
        guard let project = project else { return nil }

        return AnyView(
            List {
                Text("项目：\(project.title)")
                Text("这是我的功能列表")
            }
        )
    }
}
```

### 方案 C：创建独立标签页

```swift
class MyFeaturePlugin: SuperPlugin, PluginRegistrant, SuperLog {
    // ... 其他代码

    var isTab: Bool = true  // 设置为 true 创建标签页
}

extension MyFeaturePlugin {
    func addDetailView() -> AnyView? {
        AnyView(
            VStack {
                Text("欢迎使用我的功能")
                    .font(.title)
                Text("这是我的插件界面")
            }
        )
    }
}
```

## 步骤 5：添加预览

```swift
#Preview("MyFeature Plugin") {
    ContentLayout()
        .inRootView()
        .frame(width: 800, height: 600)
}
```

## 完整示例代码

```swift
import MagicKit
import OSLog
import SwiftUI

class MyFeaturePlugin: SuperPlugin, PluginRegistrant, SuperLog {
    // MARK: - 插件元数据
    nonisolated static let emoji = "🌟"
    nonisolated static let verbose = true

    static let label = "MyFeature"
    static var id: String = "MyFeature"
    static var displayName: String = "我的功能"
    static var description: String = "这是一个示例插件"
    static var iconName: String = "star.fill"
    static var isConfigurable: Bool = false
    static let enable = true
    static let shared = MyFeaturePlugin()

    var isTab: Bool = false

    private init() {}
}

// MARK: - 插件注册

extension MyFeaturePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register MyFeaturePlugin")
            }

            await PluginRegistry.shared.register(id: "MyFeature", order: 50) {
                MyFeaturePlugin.shared
            }
        }
    }
}

// MARK: - 视图提供

extension MyFeaturePlugin {
    func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(
            Button(action: {
                showAlert()
            }) {
                Image(systemName: iconName)
            }
            .help("打开我的功能")
        )
    }
}

// MARK: - Actions

extension MyFeaturePlugin {
    private func showAlert() {
        let alert = NSAlert()
        alert.messageText = "我的功能"
        alert.informativeText = "插件正常工作！"
        alert.alertStyle = .informational
        alert.runModal()
    }
}

// MARK: - Preview

#Preview("MyFeature Plugin") {
    ContentLayout()
        .inRootView()
        .frame(width: 800, height: 600)
}
```

## 常用模式

### 访问当前项目

```swift
struct MyView: View {
    @EnvironmentObject var data: DataProvider

    var body: some View {
        VStack {
            if let project = data.project {
                Text("当前项目：\(project.title)")
            }
        }
    }
}
```

### 监听项目变化

```swift
struct MyView: View {
    @EnvironmentObject var data: DataProvider

    var body: some View {
        VStack {}
        .onChange(of: data.project) { _, newProject in
            // 项目切换时执行
        }
    }
}
```

### 监听 Git 事件

```swift
struct MyView: View {
    var body: some View {
        VStack {}
        .onProjectDidCommit { _ in
            // 提交成功后执行
        }
    }
}
```

### 显示错误消息

```swift
struct MyView: View {
    

    var body: some View {
        VStack {}
    }

    func someMethod() {
        do {
            try something()
        } catch {
            alert_error("操作失败：\(error.localizedDescription)")
        }
    }
}
```

## 调试技巧

### 启用详细日志

```swift
nonisolated static let verbose = true
```

### 打印调试信息

```swift
os_log("\(self.t)🔍 Some value: \(someValue)")
```

### 在 Xcode 中查看日志

1. 运行应用
2. 打开 Debug Area (Cmd + Shift + Y)
3. 查看控制台输出

## 下一步

- 📖 阅读完整文档：[PLUGIN_SYSTEM.md](PLUGIN_SYSTEM.md)
- 💡 查看示例插件：`Plugins/Git/GitPlugin.swift`
- 🎨 自定义 UI：学习 SwiftUI 基础
- 🔗 集成功能：调用 LibGit2Swift API

## 常见问题

**Q: 插件没有显示？**

- 确认 `enable = true`
- 检查 `register()` 方法是否正确
- 查看控制台是否有错误

**Q: 如何访问 Git 功能？**

```swift
import LibGit2Swift

// 在 Project 实例上调用
let commits = try project.getCommits()
```

**Q: 插件之间如何通信？**

- 使用 NotificationCenter
- 或通过环境对象共享状态

**Q: 如何添加设置选项？**

- 设置 `isConfigurable = true`
- 在设置视图中添加配置 UI

---

祝开发愉快！🎉
