# GitCoreKit

GitCoreKit 是 GitOK 的 Git 操作核心库，封装了 Git 仓库模型、CLI 交互和 SSH 配置解析等底层能力。

## 功能特性

- **Git 模型定义**：Commit、Branch、Remote、Status 等核心数据模型
- **Git CLI 封装**：基于命令行的 Git 操作接口，提供类型安全的调用方式
- **SSH 配置解析**：自动解析 `~/.ssh/config`，支持自定义 SSH URL 映射

## 依赖

- [LibGit2Swift](https://github.com/nookery/LibGit2Swift.git) — libgit2 的 Swift 封装

## 系统要求

- macOS 15.0+
- Swift 6.0+

## 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "../GitCoreKit")
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
