# PluginCommitToast

提交 Toast 插件：提交成功 / 失败等事件以 Toast 形式反馈。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderToast` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCommitToast
    ├── Sources
    │   └── PluginCommitToast
    │       └── CommitToastPlugin.swift
    └── Tests
        └── PluginCommitToastTests
            └── CommitToastPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
