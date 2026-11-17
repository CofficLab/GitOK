# PluginProjects

项目插件：`ProjectManager` 管理项目列表，`ProjectSidebarProviding` 向侧边栏贡献项目入口，并提供本地添加与远程克隆按钮、工具栏控件与设置详情。

## 侧边栏展示方式（排序）

项目数量多时，侧边栏底部会出现一条**展示方式切换栏**（`AppTabBar`），提供三种排列规则：

| 展示方式 | 说明 | 是否需要 Git |
|---|---|---|
| 手动（Manual） | 沿用项目列表中保存的顺序（置顶在前，其余按用户拖拽调整的顺序） | 否 |
| 最近更新（Recent Update） | 按各仓库最近一次提交时间倒序；无提交时间的项目排在最后 | 是 |
| 名称（Name） | 按项目名称升序（不区分大小写，同名按路径） | 否 |

约定与实现要点：

- **置顶项目始终排在最前**：三种规则都把置顶组与普通组分开排序，切换展示方式不会让置顶失效。
- **点击项目不影响顺序**：点击只更新项目的最近打开时间与当前选中项；排序键不包含最近打开时间。
- **按需读取提交时间**：只有切到「最近更新」才读取提交历史；`ProjectActivityModel` 负责后台并发读取（限 4 路）、缓存结果，重复切换不重复读。
- **拖拽仅在手动排序下可用**：其他展示方式里顺序由规则决定，拖拽不会立即反映到界面，因此不挂拖放行为。
- **偏好持久化**：展示方式写入 `UserDefaults`（key `com.coffic.gitok.project-sort-mode`），重启后恢复；不写进 `projects.json`。
- **可见性阈值**：项目数少于 5 个时不显示切换栏——项目很少时列表本身就好读，多余控件只增加噪音。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`LumiLocalizationKit`、`LumiLoggingKit`、`ProviderActivity`、`ProviderGit`、`ProviderProjects`、`ProviderSettingView`、`ProviderSidebar`、`ProviderStorage`、`ProviderToast`、`ProviderToolbar`；https://github.com/CofficLab/LumiUI.git |
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
    │           ├── CloneRepositorySheet.swift
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
