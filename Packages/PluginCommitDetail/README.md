# PluginCommitDetail

提交详情插件：`CommitDetailView` 展示选中提交的完整详情与工作区变更（`WorktreeChangesView`），通过 `CommitDetailObserver` 响应选择变化。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderContentView`、`ProviderGitRepositoryWatch`、`ProviderProjects`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCommitDetail
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginCommitDetail
    │       ├── CommitDetailPlugin.swift
    │       ├── Observers
    │       │   └── CommitDetailObserver.swift
    │       ├── Support
    │       │   └── CommitDetailLocalization.swift
    │       ├── ViewModels
    │       │   └── CommitDetailViewModel.swift
    │       └── Views
    │           ├── CommitDetailLayout.swift
    │           ├── CommitDetailView.swift
    │           ├── DebugPluginBadge.swift
    │           └── WorktreeChangesView.swift
    └── Tests
        └── PluginCommitDetailTests
            └── CommitDetailPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
