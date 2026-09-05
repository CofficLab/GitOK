# PluginGitIgnore

.gitignore 查看与编辑插件：`GitIgnoreViewer` 浏览 / 编辑忽略规则，`GitIgnoreStatusIcon` 展示状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitIgnore
    ├── Sources
    │   └── PluginGitIgnore
    │       ├── GitIgnorePlugin.swift
    │       └── Views
    │           ├── GitIgnoreStatusIcon.swift
    │           └── GitIgnoreViewer.swift
    └── Tests
        └── PluginGitIgnoreTests
            └── PluginGitIgnoreTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
