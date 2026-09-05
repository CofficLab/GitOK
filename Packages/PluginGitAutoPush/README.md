# PluginGitAutoPush

Git 自动推送插件：`AutoPushStatusIcon` 展示自动推送状态并驱动自动推送行为。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderAutoPush`、`ProviderCommitForm`、`ProviderProjects`、`ProviderStatusBar`、`ProviderStorage`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitAutoPush
    ├── Sources
    │   └── PluginGitAutoPush
    │       ├── GitAutoPushPlugin.swift
    │       └── Views
    │           └── AutoPushStatusIcon.swift
    └── Tests
        └── PluginGitAutoPushTests
            └── PluginGitAutoPushTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
