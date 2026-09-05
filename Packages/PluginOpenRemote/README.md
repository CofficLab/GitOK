# PluginOpenRemote

「打开远程仓库」插件：通过 KitOpenIn 在浏览器中打开当前仓库的远程地址。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KitOpenIn` |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginOpenRemote
    └── Sources
        └── PluginOpenRemote
            └── OpenRemotePlugin.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
