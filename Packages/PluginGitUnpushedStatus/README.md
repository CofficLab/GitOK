# PluginGitUnpushedStatus

未推送状态插件：`UnpushedStatusTile` 展示尚未推送的提交数量与状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitUnpushedStatus
    ├── Sources
    │   └── PluginGitUnpushedStatus
    │       ├── GitUnpushedStatusPlugin.swift
    │       └── Views
    │           └── UnpushedStatusTile.swift
    └── Tests
        └── PluginGitUnpushedStatusTests
            └── PluginGitUnpushedStatusTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
