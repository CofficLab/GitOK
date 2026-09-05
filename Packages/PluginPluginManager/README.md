# PluginPluginManager

插件管理器插件：`PluginManagementView` 提供插件列表、启用 / 禁用控制、设置与关于页（对接 ProviderPluginManaging / ProviderPluginControl）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderDocsView`、`ProviderPluginManaging`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginPluginManager
    ├── Sources
    │   └── PluginPluginManager
    │       ├── Models
    │       │   └── PluginPluginManagerText.swift
    │       ├── PluginPluginManager.swift
    │       └── Views
    │           ├── PluginDefaultAboutView.swift
    │           ├── PluginEnableControl.swift
    │           ├── PluginListRow.swift
    │           ├── PluginManagementHeader.swift
    │           ├── PluginManagementView.swift
    │           ├── PluginManagerAboutView.swift
    │           ├── PluginManagerManualView.swift
    │           └── PluginSettingsDetailView.swift
    └── Tests
        └── PluginPluginManagerTests
            └── PluginPluginManagerTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
