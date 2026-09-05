# PluginGitBranchStatus

分支状态与管理插件：`BranchPickerView` / `BranchManagementView` / `BranchStatusTile` 提供分支切换、管理与状态展示。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`、`ProviderToolbar` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitBranchStatus
    ├── Sources
    │   └── PluginGitBranchStatus
    │       ├── GitBranchStatusPlugin.swift
    │       └── Views
    │           ├── BranchManagementView.swift
    │           ├── BranchPickerPopoverView.swift
    │           ├── BranchPickerView.swift
    │           └── BranchStatusTile.swift
    └── Tests
        └── PluginGitBranchStatusTests
            └── PluginGitBranchStatusTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
