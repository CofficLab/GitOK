# PluginSettingsButton

设置按钮插件：`SettingsButtonView` 在界面提供打开设置的入口。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderSettingView`、`ProviderToolbar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginSettingsButton
    ├── Sources
    │   └── PluginSettingsButton
    │       ├── SettingsButtonPlugin.swift
    │       └── Views
    │           └── SettingsButtonView.swift
    └── Tests
        └── PluginSettingsButtonTests
            └── SettingsButtonPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
