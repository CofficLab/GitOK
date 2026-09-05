# PluginGitRepositorySettings

仓库设置插件：`RepositorySettingView` 配置当前仓库的 Git 行为。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitRepositorySettings
    ├── Sources
    │   └── PluginGitRepositorySettings
    │       ├── GitRepositorySettingsPlugin.swift
    │       └── Views
    │           └── RepositorySettingView.swift
    └── Tests
        └── PluginGitRepositorySettingsTests
            └── PluginGitRepositorySettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
