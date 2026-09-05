# PluginCloneRepository

克隆仓库插件：`CloneRepositorySheet` 提供仓库克隆表单并执行克隆。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderActivity`、`ProviderCloneRepository`、`ProviderProjects`、`ProviderToast`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCloneRepository
    ├── Sources
    │   └── PluginCloneRepository
    │       ├── CloneRepositoryPlugin.swift
    │       └── Views
    │           └── CloneRepositorySheet.swift
    └── Tests
        └── PluginCloneRepositoryTests
            └── PluginCloneRepositoryTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
