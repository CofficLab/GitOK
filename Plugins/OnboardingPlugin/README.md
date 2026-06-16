# OnboardingPlugin

新用户引导插件，为新用户提供应用使用引导。

## 概述

此插件注册 ID 为 `OnboardingPlugin`，为新用户提供首次使用引导，包括 Git 用户配置、提交风格选择、项目信息展示等功能。

## 架构

```
OnboardingPlugin/
├── Package.swift
├── Sources/
│   ├── OnboardingPlugin.swift
│   ├── Views/
│   │   ├── GuideView.swift
│   │   ├── BranchInfoView.swift
│   │   ├── CommitStylePresetView.swift
│   │   ├── CurrentUserConfigView.swift
│   │   ├── GitUserPresetView.swift
│   │   ├── NoCommit.swift
│   │   ├── NoLocalChanges.swift
│   │   ├── NoRepositoriesGuideView.swift
│   │   ├── ProjectInfoView.swift
│   │   ├── ProjectNotFoundView.swift
│   │   ├── ProjectNotGitView.swift
│   │   ├── RemoteInfoView.swift
│   │   └── RepositoryInfoView.swift
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

- 首次使用引导流程
- Git 用户信息预设配置
- 提交风格选择引导
- 分支和远程仓库信息展示
- 无仓库/非 Git 项目的引导提示
