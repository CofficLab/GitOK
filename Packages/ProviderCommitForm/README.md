# ProviderCommitForm

提交表单领域包：定义提交分类（`CommitCategory`）、风格（`CommitStyle` / `CommitStyleStore`）、提交信息规则（`CommitMessageRules`）与 `CommitFormProviding` 协议。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitGit` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderCommitForm
    ├── Sources
    │   └── ProviderCommitForm
    │       ├── CoAuthor.swift
    │       ├── CommitCategory.swift
    │       ├── CommitFormProviding.swift
    │       ├── CommitMessageRules.swift
    │       ├── CommitStyle.swift
    │       └── CommitStyleStore.swift
    └── Tests
        └── ProviderCommitFormTests
            └── ProviderCommitFormTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
