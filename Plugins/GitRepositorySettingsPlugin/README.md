# GitRepositorySettingsPlugin

仓库设置插件，用于配置 Git 仓库相关选项。

## 概述

此插件注册 ID 为 `GitRepositorySettingsPlugin`，在设置面板中提供仓库级别的配置功能。

## 架构

```
GitRepositorySettingsPlugin/
├── Package.swift
├── Sources/
│   ├── GitRepositorySettingsPlugin.swift
│   ├── Views/
│   │   └── RepositorySettingView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitCoreKit`
- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`
- `ProjectRulesKit`

## 功能

- 仓库级别设置配置
- Git 仓库选项管理
