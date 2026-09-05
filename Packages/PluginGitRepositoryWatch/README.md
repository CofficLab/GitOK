# PluginGitRepositoryWatch

仓库监视插件：`GitDirectoryWatcher` / `WorkingTreeWatcher` 监听仓库目录变化，`GitRepositoryWatchProvider` 向外提供监视能力。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderGitRepositoryWatch`、`ProviderProjects` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitRepositoryWatch
    ├── Sources
    │   └── PluginGitRepositoryWatch
    │       ├── GitDirectorySnapshot.swift
    │       ├── GitDirectoryWatcher.swift
    │       ├── GitRepositoryWatchPlugin.swift
    │       ├── GitRepositoryWatchProvider.swift
    │       └── WorkingTreeWatcher.swift
    └── Tests
        └── PluginGitRepositoryWatchTests
            └── PluginGitRepositoryWatchTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
