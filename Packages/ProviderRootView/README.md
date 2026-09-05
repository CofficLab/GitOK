# ProviderRootView

根视图能力协议包：定义 `RootViewProviding` 与默认实现，含主内容 / 欢迎 / 工作台分割等视图组件。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitLocalization`、`KitSuperLog`、`ProviderChatSection`、`ProviderRailView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderRootView
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── ProviderRootView
    │       ├── ContentFooterHeight.swift
    │       ├── DefaultRootViewProvider.swift
    │       ├── RootViewProviding.swift
    │       ├── Support
    │       │   └── LumiPluginLocalization.swift
    │       └── Views
    │           ├── ContentPlaceholderView.swift
    │           ├── DebugBlockBadge.swift
    │           ├── DefaultRootHostView.swift
    │           ├── RootMainContentView.swift
    │           ├── RootWelcomeView.swift
    │           └── WorkbenchSplitView.swift
    └── Tests
        └── ProviderRootViewTests
            └── ProviderRootViewTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
