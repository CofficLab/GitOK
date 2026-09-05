# PluginToast

Toast 插件：`ToastOverlay` 提供全局 Toast 浮层，`ToastSuperPlugin` 装配 Toast 展示能力（对接 ProviderToast）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderRootView`、`ProviderToast`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginToast
    ├── Sources
    │   └── PluginToast
    │       ├── ToastOverlay.swift
    │       └── ToastSuperPlugin.swift
    └── Tests
        └── PluginToastTests
            └── ToastSuperPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
