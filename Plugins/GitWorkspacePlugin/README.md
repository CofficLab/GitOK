# GitWorkspacePlugin

Git 工作区管理插件，提供提交历史和代码差异查看的完整功能。

## 概述

此插件整合了 Git 提交管理和代码差异查看功能，为 GitOK 提供核心的工作区交互界面。

## 架构

```
GitWorkspacePlugin/
├── Package.swift
├── Sources/GitWorkspace/
│   ├── GitWorkspacePlugin.swift
│   ├── GitWorkspaceExports.swift
│   ├── Localizable.xcstrings
│   ├── Commit/
│   │   ├── Models/
│   │   │   ├── CommitHistoryRules.swift
│   │   │   ├── CommitMessageRules.swift
│   │   │   ├── CommitStyle.swift
│   │   │   └── ...
│   │   ├── Services/
│   │   │   ├── CommitHistoryService.swift
│   │   │   ├── GitLogService.swift
│   │   │   └── ...
│   │   └── Views/
│   │       ├── CommitHistoryView.swift
│   │       ├── CommitRowView.swift
│   │       ├── WorkingTreeStatusView.swift
│   │       └── ...
│   └── GitDetail/
│       ├── Models/
│       │   ├── DiffModels.swift
│       │   ├── DiffStats.swift
│       │   └── ...
│       ├── Services/
│       │   ├── DiffService.swift
│       │   ├── FileListService.swift
│       │   └── ...
│       └── Views/
│           ├── DiffView.swift
│           ├── FileListView.swift
│           ├── GitDetailView.swift
│           └── ...
└── Tests/
```

## 依赖

- `GitOKCoreKit`
- `GitCoreKit`
- `ProjectSupportKit`
- `ProjectRulesKit`

## 功能

### 提交历史管理
- **提交历史列表**: 分页显示 Git 提交历史
- **提交详情查看**: 查看提交的完整信息和文件变更
- **工作区状态**: 显示未提交的文件变更状态
- **提交操作**: 支持撤销提交、回退等操作

### 代码差异查看
- **文件列表**: 显示提交中变更的文件列表
- **差异视图**: 并排或内联显示代码差异
- **行级导航**: 快速跳转到变更的行
- **文件过滤**: 支持按文件类型或名称过滤

## 本地化

本插件使用 `Localizable.xcstrings` 提供多语言支持，包括：
- 英语 (en)
- 简体中文 (zh-Hans)
- 繁体中文 (zh-Hant)
- 香港繁体中文 (zh-HK)

## 配置

| 属性 | 值 |
|------|------|
| `allowUserToggle` | `false` |
| `defaultEnabled` | `true` |
