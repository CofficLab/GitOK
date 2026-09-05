# KitOpenIn

外部工具启动封装：`AppLauncher` 启动任意应用，`OpenInPluginBase` 为 PluginOpen* 系列提供「在外部打开」公共基类。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 共享工具包（Kit 层） |
| **宿主** | 被上层插件 / Provider 复用 |
| **上游依赖** | `KernelCore`、`ProviderProjects`、`ProviderToolbar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── KitOpenIn
    ├── Sources
    │   └── KitOpenIn
    │       ├── AppLauncher.swift
    │       ├── OpenInPluginBase.swift
    │       ├── OpenTarget.swift
    │       └── Views
    │           └── OpenInButton.swift
    └── Tests
        └── KitOpenInTests
            └── KitOpenInTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
