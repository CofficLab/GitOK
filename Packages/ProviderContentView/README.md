# ProviderContentView

内容视图能力协议包：定义 `ContentViewProviding` 并给出默认实现。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitLocalization`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderContentView
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── ProviderContentView
    │       ├── ContentViewProviding.swift
    │       ├── DefaultContentViewProviding.swift
    │       └── Support
    │           └── LumiPluginLocalization.swift
    └── Tests
        └── ProviderContentViewTests
            └── ProviderContentViewTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
