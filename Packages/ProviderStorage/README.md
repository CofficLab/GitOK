# ProviderStorage

存储能力协议包：定义 `StorageProviding` 与默认实现 `DefaultStorageProvider`，含插件启用状态存储。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KernelCore`、`KitSuperLog` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderStorage
    ├── Sources
    │   └── ProviderStorage
    │       ├── DefaultStorageProvider.swift
    │       ├── PluginEnabledStateStore.swift
    │       └── StorageProviding.swift
    └── Tests
        └── ProviderStorageTests
            └── ProviderStorageTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
