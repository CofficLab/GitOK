# PluginSettingGeneral

通用设置插件：`GeneralSettingsDetailView` 提供应用通用设置（版本信息 `AppVersion`、手册浏览 `ManualsBrowserView` 等）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitLocalization`、`KitSuperLog`、`ProviderCommand`、`ProviderDocsView`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginSettingGeneral
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginSettingGeneral
    │       ├── AppVersion.swift
    │       ├── SettingGeneralPlugin.swift
    │       ├── Support
    │       │   └── LumiPluginLocalization.swift
    │       └── Views
    │           ├── GeneralSettingsDetailView.swift
    │           └── ManualsBrowserView.swift
    └── Tests
        └── PluginSettingGeneralTests
            └── PluginSettingGeneralTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
