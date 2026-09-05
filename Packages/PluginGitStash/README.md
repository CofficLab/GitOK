# PluginGitStash

Git Stash 插件：`StashListView` 管理暂存列表，`StashStatusTile` 展示暂存状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitStash
    ├── Sources
    │   └── PluginGitStash
    │       ├── GitStashPlugin.swift
    │       └── Views
    │           ├── StashListView.swift
    │           └── StashStatusTile.swift
    └── Tests
        └── PluginGitStashTests
            └── PluginGitStashTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
