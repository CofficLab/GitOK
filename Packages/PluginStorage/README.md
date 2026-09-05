# PluginStorage

存储插件：`StorageSuperPlugin` 装配存储能力（对接 ProviderStorage）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderStorage` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginStorage
    └── Sources
        └── PluginStorage
            └── StorageSuperPlugin.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
