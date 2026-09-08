# PluginWorktreeClean

工作区状态插件：`WorktreeCleanView` 在顶部同一行展示工作区干净提示与本地 Git 提交活跃度热力图，下面按整行展示仓库信息、Git 用户配置与用户预设。`WorktreeCleanViewModel` / `WorktreeCleanObserver` 驱动工作区状态，热力图通过 `ProviderActivityHeatmap` 消费 `PluginActivityHeatmap` 提供的数据。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderActivityHeatmap`、`ProviderContentView`、`ProviderGitUser`、`ProviderGitRepositoryWatch`、`ProviderProjects`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginWorktreeClean
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginWorktreeClean
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
