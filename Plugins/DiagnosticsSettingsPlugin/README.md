# DiagnosticsSettingsPlugin

诊断设置插件，提供应用诊断和调试功能。

## 概述

此插件注册 ID 为 `DiagnosticsSettingsPlugin`，在设置面板中提供诊断工具，帮助用户排查应用问题。

## 架构

```
DiagnosticsSettingsPlugin/
├── Package.swift
├── Sources/
│   ├── DiagnosticsSettingsPlugin.swift
│   ├── Views/
│   │   └── DiagnosticsSettingView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitOKAppCore`
- `GitOKUI`
- `GitOKSupportKit`

## 功能

- 应用运行诊断检查
- 显示调试信息
