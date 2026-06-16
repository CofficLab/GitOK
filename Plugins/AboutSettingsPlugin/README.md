# AboutSettingsPlugin

关于页面插件，在设置面板中展示应用相关信息。

## 概述

此插件注册 ID 为 `AboutSettingsPlugin`，提供应用关于页面，展示版本信息、致谢等内容。

## 架构

```
AboutSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── AboutSettingsPlugin.swift
│   ├── Views/
│   │   └── AboutView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 展示应用版本信息
- 显示应用介绍和致谢
