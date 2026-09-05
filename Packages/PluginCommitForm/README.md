# PluginCommitForm

提交表单插件：`CommitFormView` 提供提交信息填写与提交动作。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderCommitForm`、`ProviderContentView`、`ProviderGitRepositoryWatch`、`ProviderProjects`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginCommitForm
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginCommitForm
    │       ├── CommitFormPlugin.swift
    │       ├── Support
    │       │   └── CommitFormLocalization.swift
    │       └── Views
    │           ├── CommitFormView.swift
    │           └── DebugPluginBadge.swift
    └── Tests
        └── PluginCommitFormTests
            └── PluginCommitFormTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
