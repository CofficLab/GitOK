# CommitStyleSettingsPlugin

Commit 风格设置插件，用于配置 Git 提交消息的格式风格。

## 概述

此插件注册 ID 为 `CommitStyleSettingsPlugin`，在设置面板中提供 Commit 消息风格配置功能。

## 架构

```
CommitStyleSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── CommitStyleSettingsPlugin.swift
│   ├── Views/
│   │   └── CommitStyleSettingView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 配置 Git 提交消息风格
- 管理 Commit 格式偏好设置
