# PluginGitDiff

Git Diff 插件：`GitDiffPaneView` 提供统一的差异对比面板，`GitDiffObserver` / `GitDiffViewModel` 负责加载与状态驱动。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderRootView`；https://github.com/CofficLab/LumiUI.git、https://github.com/nookery/MagicDiffView |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitDiff
    ├── Sources
    │   └── PluginGitDiff
    │       ├── GitDiffPlugin.swift
    │       ├── Observers
    │       │   └── GitDiffObserver.swift
    │       ├── ViewModels
    │       │   └── GitDiffViewModel.swift
    │       └── Views
    │           ├── DebugPluginBadge.swift
    │           └── GitDiffPaneView.swift
    └── Tests
        └── PluginGitDiffTests
            └── GitDiffPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
