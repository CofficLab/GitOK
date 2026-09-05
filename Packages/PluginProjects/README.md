# PluginProjects

项目插件：`ProjectManager` 管理项目列表，`ProjectSidebarProviding` 向侧边栏贡献项目入口，并提供工具栏控件与设置详情。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`KitSuperLog`、`ProviderCloneRepository`、`ProviderProjects`、`ProviderSettingView`、`ProviderSidebar`、`ProviderStorage`、`ProviderToolbar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginProjects
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── PluginProjects
    │       ├── ProjectManager.swift
    │       ├── ProjectSidebarProviding.swift
    │       ├── ProjectsPlugin.swift
    │       ├── Support
    │       │   ├── LumiPluginLocalization.swift
    │       │   └── ProjectObservationModel.swift
    │       └── Views
    │           ├── ProjectToolbarControlView.swift
    │           ├── ProjectToolbarPopoverView.swift
    │           └── ProjectsSettingsDetailView.swift
    └── Tests
        └── PluginProjectsTests
            └── PluginProjectsTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
