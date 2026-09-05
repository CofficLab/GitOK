# PluginGitNetworkSettings

Git 网络设置插件：`GitNetworkSettingView` 配置 Git 网络参数（代理、超时等，对接 KitGit 的 GitNetworkConfig）。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderSettingView`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitNetworkSettings
    ├── Sources
    │   └── PluginGitNetworkSettings
    │       ├── GitNetworkSettingsPlugin.swift
    │       └── Views
    │           └── GitNetworkSettingView.swift
    └── Tests
        └── PluginGitNetworkSettingsTests
            └── PluginGitNetworkSettingsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
