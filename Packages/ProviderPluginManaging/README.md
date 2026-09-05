# ProviderPluginManaging

插件管理能力协议包：定义 `PluginManaging` 与默认实现 `DefaultPluginManager`（含错误类型）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KernelCore`、`ProviderPluginControl` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderPluginManaging
    ├── Sources
    │   └── ProviderPluginManaging
    │       ├── DefaultPluginManager.swift
    │       ├── PluginManaging.swift
    │       └── PluginManagingError.swift
    └── Tests
        └── ProviderPluginManagingTests
            └── PluginManagingTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
