# GitOKAutomationKit

`GitOKAutomationKit` 为 GitOK 的 Debug 构建提供一层轻量的本地自动化接口。AI Agent 或 shell 脚本可以通过 HTTP 触发指定的 App 行为，GitOK 视图则通过类型化的 SwiftUI 事件扩展消费这些动作。

这个 package 有意保持和 GitOK App 业务模型解耦。它不知道 `ProjectVM`、commit、文件或插件类型，只负责定义 HTTP 协议、事件分发和方便视图使用的 SwiftUI modifier。

## 运行链路

```text
AI Agent / shell 脚本
  -> POST http://127.0.0.1:18766/api/action
  -> GitOKAutomationService 解析 action + payload
  -> NotificationCenter 发出 gitOKAutomationActionReceived
  -> SwiftUI 视图通过 .onMockCommitSelected 等 modifier 响应
  -> App 代码更新 VM 或 UI 状态
  -> Agent 读取 App 日志或状态进行验证
```

## 启动服务

GitOK 应在 App 启动后启动服务，通常只在 Debug 构建中启用：

```swift
#if DEBUG
import GitOKAutomationKit

GitOKAutomationService.shared.start()
#endif
```

默认端口：`18766`

可以通过环境变量关闭：

```bash
GITOK_AUTOMATION_SERVER=false
```

服务绑定到 `127.0.0.1`，只接受 `POST /api/action`。

## HTTP API

```bash
curl -s -X POST http://127.0.0.1:18766/api/action \
  -H "Content-Type: application/json" \
  -d '{"action":"mock.commit.selected","payload":{"hash":"abc123"}}'
```

成功响应：

```json
{"status":"ok","message":"动作已分发"}
```

## 动作

第一版支持的动作名：

- `mock.commit.selected`
- `mock.working_tree.selected`
- `mock.file.selected`
- `mock.project.selected`
- `state.snapshot`

Payload 字段：

- `hash`：用于 commit 选择
- `path`：用于文件或项目选择

## SwiftUI 用法

```swift
SomeView()
    .onMockCommitSelected { hash in
        // 在 App 侧根据 hash 找到 commit，并更新 VM 状态。
    }
    .onMockWorkingTreeSelected {
        // 切回工作区模式。
    }
    .onMockFileSelected { path in
        // 选中文件。
    }
    .onMockProjectSelected { path in
        // 选中项目。
    }
```

## 安全约束

- App target 中应只在 Debug 环境启用。
- 不要添加任意 shell 命令执行类 action。
- 优先添加白名单、语义化 action，并映射到真实 App 工作流。
- 测试不应只验证 HTTP `ok`，还应验证 App 侧日志或状态变化。
