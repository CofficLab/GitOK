# ProviderLogo

Logo 能力协议包：定义 `LogoProviding` / `LogoItem` / `LogoScene` 并给出默认实现。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | 无（独立包） |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderLogo
    ├── Sources
    │   └── ProviderLogo
    │       ├── DefaultLogoProviding.swift
    │       ├── LogoItem.swift
    │       ├── LogoProviding.swift
    │       └── LogoScene.swift
    └── Tests
        └── ProviderLogoTests
            └── ProviderLogoTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
