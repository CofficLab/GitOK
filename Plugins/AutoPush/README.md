# AutoPush Plugin

自动推送插件 - 定时自动推送当前分支到远程仓库。

## 目录结构

```
AutoPush/
├── AutoPushPlugin.swift                 # 插件主体
├── AutoPush.xcstrings                    # 多语言资源文件
├── AutoPushService.swift               # 自动推送服务
├── AutoPushSettingsStore.swift         # 配置存储服务
├── AutoPushStatusIcon.swift            # 状态栏图标
└── Views/                             # UI 视图
    ├── StatusBar/                      # 状态栏组件
    │   └── AutoPushStatusBarView.swift
    ├── AutoPushConfigView.swift       # 配置主视图
    ├── AutoPushConfigHeaderView.swift  # 配置标题栏
    ├── CurrentProjectSectionView.swift # 当前项目区块
    ├── ConfiguredProjectsSectionView.swift # 已配置项目区块
    └── ConfigRowView.swift             # 配置行视图
```

## 功能说明

- ✅ 支持为每个项目分支单独配置自动推送
- ✅ 每 30 秒自动检查并推送未推送的提交
- ✅ 可视化配置界面，支持启用/禁用/删除配置
- ✅ 状态栏实时显示自动推送状态
- ✅ 支持多语言（英文/简体中文/繁体中文）

## 使用说明

1. 点击状态栏的自动推送图标
2. 在配置界面中为需要的项目分支启用自动推送
3. 启用后会自动推送，无需手动操作

## 技术栈

- Swift 5.9+
- SwiftUI
- LibGit2
- SwiftData
- os.Logger

## 遵循的规范

- ✅ 日志记录规范 (`.agent/rules/logging-standards.md`)
- ✅ 多语言规范 (`.agent/rules/i18n-standards.md`)
- ✅ 插件目录结构规范 (`.agent/rules/plugin-structure-standards.md`)
