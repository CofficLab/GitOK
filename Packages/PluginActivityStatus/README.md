# PluginActivityStatus

活动状态插件：`ActivityStatusTile` 在界面展示当前活动状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderActivity`、`ProviderStatusBar` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginActivityStatus
    ├── Sources
    │   └── PluginActivityStatus
    │       ├── ActivityStatusPlugin.swift
    │       └── ActivityStatusTile.swift
    └── Tests
        └── PluginActivityStatusTests
            └── PluginActivityStatusTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
