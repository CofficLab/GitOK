# ProviderAutoPush

自动推送能力协议包：定义 `AutoPushProviding`，抽象自动推送行为。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KernelCore`、`ProviderStorage` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderAutoPush
    ├── Sources
    │   └── ProviderAutoPush
    │       └── AutoPushProviding.swift
    └── Tests
        └── ProviderAutoPushTests
            └── ProviderAutoPushTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
