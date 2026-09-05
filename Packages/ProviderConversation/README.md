# ProviderConversation

对话管理能力协议包：定义 `ConversationManaging` 与默认实现 `DefaultConversationManager`，含自动化级别、推理强度、回复详略等模型。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `KitSuperLog` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderConversation
    ├── Sources
    │   └── ProviderConversation
    │       ├── AutomationLevel.swift
    │       ├── ConversationLanguage.swift
    │       ├── ConversationManaging.swift
    │       ├── ConversationObservation.swift
    │       ├── ConversationSummary.swift
    │       ├── DefaultConversationManager.swift
    │       ├── ReasoningEffort.swift
    │       └── ResponseVerbosity.swift
    └── Tests
        └── ProviderConversationTests
            └── ProviderConversationTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
