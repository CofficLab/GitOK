# PluginToast

Toast 插件：`ToastOverlay` 提供全局 Toast 浮层，`ToastSuperPlugin` 装配 Toast 展示能力（对接 ProviderToast）。

弹出视图（Toast 横幅、持久化错误面板）由 [LumiUI](https://github.com/CofficLab/LumiUI) 组件与设计令牌绘制，
本插件只负责状态机与排版定位，不自行拼装视觉样式。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderRootView`、`ProviderToast`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginToast
    ├── Sources
    │   └── PluginToast
    │       ├── ToastCenter.swift           # Toast 状态机（ToastProviding 实现）
    │       ├── ToastSuperPlugin.swift      # 插件装配与覆盖层挂载
    │       └── Views
    │           ├── ToastOverlay.swift      # 根覆盖层（订阅状态、定位）
    │           ├── ToastBannerView.swift   # 单条 Toast（AppStatusBanner）
    │           ├── ErrorNoticeOverlay.swift# 持久化错误面板
    │           └── ToastAboutView.swift    # 关于页
    └── Tests
        └── PluginToastTests
            └── ToastSuperPluginTests.swift
```

## 绘制所用的 LumiUI 组件

| 用途 | 组件 / 令牌 |
|------|-------------|
| Toast 横幅 | `AppStatusBanner` + `appShadow` |
| 错误面板容器 | `appSurface(.panel)` / `appShadow` |
| 错误图标 | `ErrorIconView` |
| 分隔与分组标题 | `AppDivider` / `AppSectionLabel` |
| 复制与关闭操作 | `CopyMessageButton` / `AppButton` |
| 转场与动画 | `appStatusPresentationTransition` / `LumiMotion` |

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
