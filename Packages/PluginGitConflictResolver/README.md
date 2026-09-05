# PluginGitConflictResolver

冲突解决插件：`ConflictResolverList` 列出冲突文件并引导解决，`ConflictStatusTile` 展示冲突状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitConflictResolver
    ├── Sources
    │   └── PluginGitConflictResolver
    │       ├── GitConflictResolverPlugin.swift
    │       └── Views
    │           ├── ConflictResolverList.swift
    │           └── ConflictStatusTile.swift
    └── Tests
        └── PluginGitConflictResolverTests
            └── PluginGitConflictResolverTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
