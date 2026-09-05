# PluginRootView

根视图插件：`RootViewPlugin` 组织主内容根视图，`NoProjectGuideView` 展示未打开项目时的引导。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitLocalization`、`KitSuperLog`、`ProviderCloneRepository`、`ProviderProjects`、`ProviderRootView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginRootView
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginRootView
    │       ├── Observers
    │       │   └── RootViewProjectObserver.swift
    │       ├── RootViewPlugin.swift
    │       ├── Support
    │       │   └── LumiPluginLocalization.swift
    │       └── Views
    │           └── NoProjectGuideView.swift
    └── Tests
        └── PluginRootViewTests
            └── PluginRootViewTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
