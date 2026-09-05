# KitGit

Git 命令行封装工具包：进程运行、分支 / 克隆 / 提交 / 合并 / 暂存 / 远程 / 子模块等操作，status / diff / commit 加载与提交图布局。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 共享工具包（Kit 层） |
| **宿主** | 被上层插件 / Provider 复用 |
| **上游依赖** | 无（独立包） |
| **平台** | macOS 14+ |

## 目录结构

```text
└── KitGit
    ├── Sources
    │   └── KitGit
    │       ├── CommitGraphLayoutRules.swift
    │       ├── GitBranchOperation.swift
    │       ├── GitCloneOperation.swift
    │       ├── GitCommit.swift
    │       ├── GitCommitLoader.swift
    │       ├── GitCommitOperation.swift
    │       ├── GitConfigReader.swift
    │       ├── GitDiffLoader.swift
    │       ├── GitMergeOperation.swift
    │       ├── GitNetworkConfig.swift
    │       ├── GitProcessRunner.swift
    │       ├── GitRefReader.swift
    │       ├── GitRemoteOperation.swift
    │       ├── GitStashOperation.swift
    │       ├── GitStatusLoader.swift
    │       └── GitSubmoduleOperation.swift
    └── Tests
        └── KitGitTests
            ├── GitCloneOperationTests.swift
            ├── GitCommitLoaderTests.swift
            ├── GitCommitOperationTests.swift
            └── GitDiffLoaderTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
