# PluginCommitStatusBar

提交状态栏插件：在状态栏展示当前提交相关状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCommitStatusBar
    ├── Sources
    │   └── PluginCommitStatusBar
    │       └── CommitStatusBarPlugin.swift
    └── Tests
        └── PluginCommitStatusBarTests
            └── CommitStatusBarPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
