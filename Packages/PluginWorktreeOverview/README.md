# PluginWorktreeOverview

工作区概览插件（显示名 Worktree Overview）：`WorktreeCleanView` 在顶部展示工作区状态提示（干净 / 有未提交变更）与本地 Git 提交活跃度热力图，下面按整行展示项目语言、仓库信息、Git 用户配置与用户预设。工作区干净与否都会展示；有未提交变更时，变更文件列表由 `PluginCommitDetail` 在工作区上方展示，本插件概览在其下方继续展示。`WorktreeCleanViewModel` / `WorktreeCleanObserver` 驱动工作区状态，热力图通过 `ProviderActivityHeatmap` 消费 `PluginActivityHeatmap` 提供的数据。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderActivityHeatmap`、`ProviderContentView`、`ProviderGitUser`、`ProviderGitRepositoryWatch`、`ProviderProjects`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginWorktreeOverview
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginWorktreeOverview
    │       ├── Capabilities
    │       │   └── WorktreeCleanActivityHeatmapCapability.swift
    │       ├── Observers
    │       │   ├── WorktreeCleanActivityHeatmapObserver.swift
    │       │   └── WorktreeCleanObserver.swift
    │       ├── Support
    │       │   └── WorktreeCleanLocalization.swift
    │       ├── ViewModels
    │       │   ├── WorktreeCleanActivityHeatmapViewModel.swift
    │       │   └── WorktreeCleanViewModel.swift
    │       ├── Views
    │       │   ├── CleanStateInfoView.swift
    │       │   ├── GitUserPresetSectionView.swift
    │       │   ├── DebugPluginBadge.swift
    │       │   ├── WorktreeCleanActivityHeatmapView.swift
    │       │   └── WorktreeCleanView.swift
    │       └── WorktreeCleanPlugin.swift
    └── Tests
        └── PluginWorktreeOverviewTests
            └── WorktreeCleanPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
