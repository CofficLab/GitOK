# ProviderGit

Git 能力协议包：定义业务插件消费的 `GitProviding`、后端注册协议、稳定路由器，
以及 Git 用户预设能力。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitGit`（复用当前公共 Git 值类型；实现由后端插件提供） |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderGit
    ├── Sources
    │   └── ProviderGit
    │       ├── DefaultGitProvider.swift
    │       ├── GitProviding.swift
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
