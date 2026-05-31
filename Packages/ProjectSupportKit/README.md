# ProjectSupportKit

ProjectSupportKit 是 GitOK 的项目支持库，提供项目管理中的持久化、状态存储和 Git 操作辅助功能。

## 功能特性

- **项目路径解析**：解析和规范化项目打开路径
- **文档解析器**：识别项目类型和文档结构
- **主题状态持久化**：保存和恢复用户的主题偏好设置
- **Commit 选择存储**：记录用户的 Commit 选中状态
- **Auto Push 配置**：分支级别的自动推送配置持久化
- **冲突解决状态**：管理合并冲突的解决进度
- **Co-Author 管理**：提交协作作者的存储与管理
- **Git 操作事件描述**：为 Git 操作提供用户友好的描述信息

## 依赖

- [GitCoreKit](../GitCoreKit) — Git 操作核心库

## 系统要求

- macOS 15.0+
- Swift 6.0+

## 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "../ProjectSupportKit")
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
