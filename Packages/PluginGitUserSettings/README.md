# PluginGitUserSettings

Git 用户设置插件：`GitUserInfoSettingView` 配置 user.name / user.email 等用户信息（对接 ProviderGit 的 GitUserPreset）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderGit`、`ProviderProjects`、`ProviderSettingView`、`ProviderStorage`、`ProviderToast`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitUserSettings
    ├── Sources
    │   └── PluginGitUserSettings
    │       ├── GitUserSettingsPlugin.swift
    │       └── Views
    │           └── GitUserInfoSettingView.swift
    └── Tests
        └── PluginGitUserSettingsTests
            └── PluginGitUserSettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
