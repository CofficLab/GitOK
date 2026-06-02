# GitOKCoreKit

GitOKCoreKit 是 GitOK 的插件框架库，定义了插件的上下文环境、打包规范和生命周期管理。

## 功能特性

- **插件上下文**：提供插件运行时所需的环境信息和 API 接口
- **打包插件**：支持将插件打包为可分发格式，便于安装和管理
- **本地化支持**：内置多语言资源管理（默认英语）

## 依赖

- [GitOKUI](../GitOKUI) — GitOK 设计系统与 UI 组件库

## 系统要求

- macOS 14.0+
- Swift 6.0+

## 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "../GitOKCoreKit")
]
```

## 构建

```bash
swift build
```

## 测试

```bash
swift test
```

## Maintainers

Work for Joy & Live for Love ➡️ <https://github.com/nookery>
