# PluginDiagnosticsSettings

诊断设置插件：`DiagnosticsSettingView` 提供诊断与调试相关设置项。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginDiagnosticsSettings
    ├── Sources
    │   └── PluginDiagnosticsSettings
    │       ├── DiagnosticsSettingsPlugin.swift
    │       └── Views
    │           └── DiagnosticsSettingView.swift
    └── Tests
        └── PluginDiagnosticsSettingsTests
            └── PluginDiagnosticsSettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
