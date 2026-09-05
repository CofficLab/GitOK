# PluginLicense

许可证插件：`LicenseViewer` 查看第三方许可证，`LicenseStatusIcon` 展示入口状态。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用插件（SwiftPM 包） |
| **宿主** | `KernelCore`（`SuperPlugin` 生命周期） |
| **上游依赖** | `KernelCore`、`KitSuperLog`、`ProviderProjects`、`ProviderStatusBar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── PluginLicense
    ├── Sources
    │   └── PluginLicense
    │       ├── LicensePlugin.swift
    │       └── Views
    │           ├── LicenseStatusIcon.swift
    │           └── LicenseViewer.swift
    └── Tests
        └── PluginLicenseTests
            └── PluginLicenseTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
