# AppearanceSettingsPlugin

外观设置插件，用于配置应用界面外观。

## 概述

此插件注册 ID 为 `AppearanceSettingsPlugin`，在设置面板中提供应用外观配置功能，支持主题切换等。

## 架构

```
AppearanceSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── AppearanceSettingsPlugin.swift
│   ├── Views/
│   │   └── AppAppearanceSettingView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 应用主题切换（亮色/暗色/跟随系统）
- 界面外观配置
