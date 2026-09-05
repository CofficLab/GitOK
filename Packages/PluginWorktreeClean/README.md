# PluginWorktreeClean

工作区清理插件：`WorktreeCleanView` 展示可清理内容，`WorktreeCleanViewModel` / `WorktreeCleanObserver` 驱动清理流程。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderContentView`、`ProviderGitRepositoryWatch`、`ProviderProjects`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginWorktreeClean
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginWorktreeClean
    │       ├── Observers
    │       │   └── WorktreeCleanObserver.swift
    │       ├── Support
    │       │   └── WorktreeCleanLocalization.swift
    │       ├── ViewModels
    │       │   └── WorktreeCleanViewModel.swift
    │       ├── Views
    │       │   ├── CleanStateInfoView.swift
    │       │   ├── DebugPluginBadge.swift
    │       │   └── WorktreeCleanView.swift
    │       └── WorktreeCleanPlugin.swift
    └── Tests
        └── PluginWorktreeCleanTests
            └── WorktreeCleanPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
