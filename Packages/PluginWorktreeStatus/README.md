# PluginWorktreeStatus

工作区状态插件：`WorkingTreeStatusView` 展示工作区文件变更状态。

主操作按钮采用 Branch Pulse 视觉：使用当前 Lumi 主题的语义色绘制扁平调色胶囊、主操作图标和远程 ahead/behind badge；Push、Sync 与首次加载使用自定义状态动画，不使用系统默认的 `ProgressView`。动画遵循 Lumi 的 Reduce Motion 设置。

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
