# PluginFileInfo

文件信息插件：`FileInfoTile` 展示当前文件的基础信息。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginFileInfo
    ├── Sources
    │   └── PluginFileInfo
    │       ├── FileInfoPlugin.swift
    │       └── Views
    │           └── FileInfoTile.swift
    └── Tests
        └── PluginFileInfoTests
            └── PluginFileInfoTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
