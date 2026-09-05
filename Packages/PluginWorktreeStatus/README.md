# PluginWorktreeStatus

工作区状态插件：`WorkingTreeStatusView` 展示工作区文件变更状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderGitRepositoryWatch`、`ProviderProjects`、`ProviderRailView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginWorktreeStatus
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginWorktreeStatus
    │       ├── Support
    │       │   └── WorktreeStatusLocalization.swift
    │       ├── Views
    │       │   └── WorkingTreeStatusView.swift
    │       └── WorktreeStatusPlugin.swift
    └── Tests
        └── PluginWorktreeStatusTests
            └── PluginWorktreeStatusTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
