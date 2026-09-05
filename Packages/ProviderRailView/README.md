# ProviderRailView

侧栏视图能力协议包：定义 `RailViewProviding` / `RailTabItem` / `RailSectionItem` 并给出默认实现。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderRailView
    ├── Sources
    │   └── ProviderRailView
    │       ├── DefaultRailViewProviding.swift
    │       ├── RailSectionItem.swift
    │       ├── RailTabItem.swift
    │       └── RailViewProviding.swift
    └── Tests
        └── ProviderRailViewTests
            └── ProviderRailViewTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
