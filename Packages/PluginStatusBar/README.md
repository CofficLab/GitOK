# PluginStatusBar

状态栏插件：`ProjectStatusBarItem` / `ThemeStatusBarItem` 等向状态栏贡献项目与主题状态项。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`、`ProviderTheme`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginStatusBar
    ├── Sources
    │   └── PluginStatusBar
    │       ├── StatusBarPlugin.swift
    │       └── Views
    │           ├── ProjectStatusBarItem.swift
    │           └── ThemeStatusBarItem.swift
    └── Tests
        └── PluginStatusBarTests
            └── StatusBarPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
