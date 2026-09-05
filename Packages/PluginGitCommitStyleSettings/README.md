# PluginGitCommitStyleSettings

提交风格设置插件：`CommitStyleSettingView` 配置提交信息风格（对接 ProviderCommitForm 的 CommitStyle）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderCommitForm`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitCommitStyleSettings
    ├── Sources
    │   └── PluginGitCommitStyleSettings
    │       ├── GitCommitStyleSettingsPlugin.swift
    │       └── Views
    │           └── CommitStyleSettingView.swift
    └── Tests
        └── PluginGitCommitStyleSettingsTests
            └── PluginGitCommitStyleSettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
