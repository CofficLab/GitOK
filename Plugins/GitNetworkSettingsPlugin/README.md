# GitNetworkSettingsPlugin

Git 网络设置插件，用于配置 Git 网络相关选项。

## 概述

此插件注册 ID 为 `GitNetworkSettingsPlugin`，在设置面板中提供 Git 网络配置功能，包括代理设置等网络相关选项。

## 架构

```
GitNetworkSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── GitNetworkSettingsPlugin.swift
│   ├── Views/
│   │   ├── GitNetworkSettingView.swift
│   │   └── GitNetworkSettingsStore.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitCoreKit`
- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 配置 Git 网络代理
- 管理网络连接设置
