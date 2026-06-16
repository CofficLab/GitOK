# ProjectsPlugin

项目列表插件，提供项目侧边栏管理和仓库操作功能。

## 概述

此插件注册 ID 为 `ProjectsPlugin`，提供项目侧边栏视图，支持项目管理、克隆仓库等操作。

## 架构

```
ProjectsPlugin/
├── Package.swift
├── Sources/
│   ├── ProjectsPlugin.swift
│   ├── Views/
│   │   ├── ProjectsView.swift
│   │   ├── ProjectRow.swift
│   │   ├── ProjectContextMenu.swift
│   │   ├── Projects+Action.swift
│   │   ├── Projects+Event.swift
│   │   └── CloneRepository/
│   │       ├── CloneRepositorySheet.swift
│   │       └── GitCloneLocalization.swift
│   ├── Localizable.xcstrings
│   └── Views/CloneRepository/GitCloneLocalizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`
- `ProjectRulesKit`

## 功能

- 项目列表侧边栏显示
- 项目上下文菜单操作
- 克隆远程仓库
- 项目事件处理
