# PluginCommitList

提交列表插件：`CommitGraphView`（提交图）与 `CommitRailView`（提交轨道）展示仓库提交历史。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderGitRepositoryWatch`、`ProviderProjects`、`ProviderRailView`、`ProviderRootView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCommitList
    ├── Sources
    │   └── PluginCommitList
    │       ├── CommitListPlugin.swift
    │       └── Views
    │           ├── CommitGraphView.swift
    │           └── CommitRailView.swift
    └── Tests
        └── PluginCommitListTests
            └── CommitListPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
