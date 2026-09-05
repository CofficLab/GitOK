# ProviderSidebar

侧边栏能力协议包：定义 `SidebarProviding` / `SidebarItem` 与默认实现，含 `SidebarView`。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitLocalization`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderSidebar
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── ProviderSidebar
    │       ├── DefaultSidebarProvider.swift
    │       ├── ProviderSidebarLocalization.swift
    │       ├── SidebarItem.swift
    │       ├── SidebarProviding.swift
    │       └── Views
    │           ├── EmptyView.swift
    │           └── SidebarView.swift
    └── Tests
        └── ProviderSidebarTests
            └── ProviderSidebarTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
