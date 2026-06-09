# BannerCoreKit

BannerCoreKit 是 GitOK 的 Banner 管理核心库，提供 Banner 文档模型、仓库索引、模板目录和数据持久化能力。

## 功能特性

- **Banner 文档模型**：定义 Banner 的数据结构与文档表示
- **Banner 记录**：管理 Banner 的增删改查记录
- **模板目录**：提供 Banner 模板的浏览与检索
- **仓库索引**：为 Banner 关联的 Git 仓库建立索引
- **数据持久化**：Banner 模板数据的本地存储与读取

## 系统要求

- macOS 14.0+
- Swift 6.0+

## 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "../BannerCoreKit")
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
