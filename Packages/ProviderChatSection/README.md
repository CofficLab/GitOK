# ProviderChatSection

对话分区能力协议包：定义 `ChatSectionItem` / `ChatSectionProviding` 并给出默认实现。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主内核 / `FactoryGitOK` 装配 |
| **上游依赖** | `ProviderConversation`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── ProviderChatSection
    ├── Sources
    │   └── ProviderChatSection
    │       ├── ChatSectionItem.swift
    │       ├── ChatSectionProviding.swift
    │       └── DefaultChatSectionProviding.swift
    └── Tests
        └── ProviderChatSectionTests
            └── ProviderChatSectionTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
