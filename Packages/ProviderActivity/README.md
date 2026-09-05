# ProviderActivity

活动能力协议包：定义 `ActivityProviding`，供活动状态展示方与提供方解耦。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | 无（独立包） |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderActivity
    ├── Sources
    │   └── ProviderActivity
    │       └── ActivityProviding.swift
    └── Tests
        └── ProviderActivityTests
            └── ProviderActivityTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
