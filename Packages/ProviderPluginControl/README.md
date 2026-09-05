# ProviderPluginControl

插件控制能力协议包：定义 `PluginControlling`，抽象插件的启用 / 禁用控制。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KernelCore` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderPluginControl
    ├── Sources
    │   └── ProviderPluginControl
    │       └── PluginControlling.swift
    └── Tests
        └── ProviderPluginControlTests
            └── PluginControllingTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
