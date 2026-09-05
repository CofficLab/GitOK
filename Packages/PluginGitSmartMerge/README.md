# PluginGitSmartMerge

智能合并插件：`MergeStatusTile` 展示合并状态并辅助合并流程。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitSmartMerge
    ├── Sources
    │   └── PluginGitSmartMerge
    │       ├── GitSmartMergePlugin.swift
    │       └── Views
    │           └── MergeStatusTile.swift
    └── Tests
        └── PluginGitSmartMergeTests
            └── PluginGitSmartMergeTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
