# PluginGitDiff

Git Diff 插件：`GitDiffPaneView` 提供统一的差异与文件预览面板，`GitDiffObserver` / `GitDiffViewModel` 负责加载与状态驱动。

## 文件预览

- 文本文件继续使用 `MagicDiffView` 展示 unified diff。
- PDF 支持新增、修改、删除场景；修改时可以在新旧版本之间切换，并显示页数摘要。
- PNG、JPEG 等图片直接内嵌预览；音频和视频使用原生播放器。
- Office 和其他二进制文件显示类型、大小及降级说明，并可用默认 macOS 应用打开。
- 二进制内容通过原始 `Data` 读取，不经过文本解码；单个内嵌预览限制为 50 MB。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitSuperLog`、`ProviderProjects`、`ProviderRootView`；https://github.com/CofficLab/LumiUI.git、https://github.com/nookery/MagicDiffView |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginGitDiff
    ├── Sources
    │   └── PluginGitDiff
    │       ├── GitDiffPlugin.swift
    │       ├── Observers
    │       │   └── GitDiffObserver.swift
    │       ├── ViewModels
    │       │   └── GitDiffViewModel.swift
    │       ├── Support
    │       │   └── GitDiffContent.swift
    │       └── Views
    │           ├── DebugPluginBadge.swift
    │           ├── GitBinaryPreviewView.swift
    │           └── GitDiffPaneView.swift
    └── Tests
        └── PluginGitDiffTests
            └── GitDiffPluginTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
