# GitUserSettingsPlugin

Git 用户信息管理插件，用于配置和管理 Git 用户名和邮箱。

## 概述

此插件注册 ID 为 `GitUserSettingsPlugin`，在设置面板中提供 Git 用户信息管理功能。支持多个用户预设配置，方便在不同项目间快速切换 Git 身份信息。

## 架构

```
GitUserSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── GitUserSettingsPlugin.swift
│   ├── Views/
│   │   ├── GitUserInfoSettingView.swift
│   │   └── UserInfoConfigView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 管理全局 Git 用户配置
- 支持多用户预设配置
- 快速切换 Git 身份信息
