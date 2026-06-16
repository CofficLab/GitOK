# UpdatePlugin

应用更新插件，使用 Sparkle 框架检查和安装应用更新。

## 概述

此插件注册 ID 为 `UpdatePlugin`，由 [Sparkle](https://sparkle-project.org) 框架驱动，提供应用自动更新和手动检查更新功能。

## 架构

```
UpdatePlugin/
├── Package.swift
├── Sources/UpdatePlugin/
│   ├── UpdatePlugin.swift
│   └── Views/
│       ├── UpdateSettingsView.swift
│       └── UpdateStatusView.swift
└── Tests/UpdatePluginTests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`
- [Sparkle](https://github.com/sparkle-project/Sparkle) (2.6.4+)

## 功能

- 自动检查应用更新
- 显示更新状态和版本信息
- 手动触发更新检查
- 更新设置选项
