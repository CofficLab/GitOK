# OpenLumiPlugin

在 Lumi 中打开项目插件，提供快捷操作按钮在 Lumi 编辑器中打开当前项目。

## 概述

此插件注册 ID 为 `OpenLumiPlugin`，提供一个快捷按钮，允许用户在 [Lumi](https://kiro.dev) 编辑器中打开当前项目。

## 架构

```
OpenLumiPlugin/
├── Package.swift
├── Sources/
│   ├── OpenLumiPlugin.swift
│   ├── OpenLumiButton.swift
│   ├── LumiProjectLauncher.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKSupportKit` (GitOKDesignKit)
- `GitOKUI`

## 功能

- 快捷按钮在 Lumi 编辑器中打开项目
- 项目启动器集成
