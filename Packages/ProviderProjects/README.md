# ProviderProjects

项目能力协议包：定义 `ProjectProviding` 与项目模型 `Project`。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitGit` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderProjects
    ├── Sources
    │   └── ProviderProjects
    │       ├── Project.swift
    │       └── ProjectProviding.swift
    └── Tests
        └── ProviderProjectsTests
            └── ProviderProjectsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
