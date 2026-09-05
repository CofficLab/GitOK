# PluginAboutSettings

「关于」设置插件：`AboutView` 展示应用信息，`AboutSettingsPlugin` 向设置页注册入口。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginAboutSettings
    ├── Sources
    │   └── PluginAboutSettings
    │       ├── AboutSettingsPlugin.swift
    │       └── Views
    │           └── AboutView.swift
    └── Tests
        └── PluginAboutSettingsTests
            └── PluginAboutSettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
