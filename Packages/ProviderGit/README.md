# ProviderGit

Git 用户预设能力协议包：定义 `GitUserPresetProviding`、`GitUserPreset` 与默认预设提供者。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | 无（独立包） |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderGit
    ├── Sources
    │   └── ProviderGit
    │       ├── DefaultGitUserPresetProvider.swift
    │       ├── GitUserPreset.swift
    │       └── GitUserPresetProviding.swift
    └── Tests
        └── ProviderGitTests
            └── ProviderGitTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
