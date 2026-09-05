# PluginThemePack

主题包插件：内置主题目录（`LegacyThemeCatalog`）与主题设置详情视图 `ThemeSettingsDetailView`（对接 ProviderTheme）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitLocalization`、`KitSuperLog`、`ProviderCommand`、`ProviderSettingView`、`ProviderTheme`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginThemePack
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginThemePack
    │       ├── LegacyThemeCatalog.swift
    │       ├── Support
    │       │   └── LumiPluginLocalization.swift
    │       ├── ThemePackPlugin.swift
    │       └── ThemeSettingsDetailView.swift
    └── Tests
        └── PluginThemePackTests
            └── ThemePackPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
