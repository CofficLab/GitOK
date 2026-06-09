# MagicAlert

MagicAlert 是一个跨平台 SwiftUI Toast / Alert 组件库，为 macOS 和 iOS 应用提供优雅的消息提示体验。

## 功能特性

- **Toast 视图**：支持成功、错误、警告、信息等多种类型的 Toast 提示
- **Toast 容器**：自动管理 Toast 的显示、堆叠和消失动画
- **全局 Alert**：提供便捷的全局弹窗函数，一行代码即可展示提示
- **自定义样式**：丰富的 Toast 外观定制选项
- **错误扩展**：将 Swift Error 自动转换为用户友好的提示信息
- **View 扩展**：为任意 SwiftUI 视图添加 Toast 能力

## 系统要求

- macOS 14.0+ / iOS 17.0+
- Swift 5.9+

## 安装

### Swift Package Manager

将以下依赖添加到您的 `Package.swift` 文件中：

```swift
dependencies: [
    .package(url: "https://github.com/nookery/MagicAlert.git", from: "1.0.0")
]
```

然后在目标中添加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "MagicAlert", package: "MagicAlert")
    ]
)
```

## 快速使用

```swift
import MagicAlert

// 显示成功 Toast
ToastManager.shared.show("操作成功")

// 显示错误 Toast
ToastManager.shared.showError("网络请求失败")
```

## 构建

```bash
swift build
```

## Maintainers

Work for Joy & Live for Love ➡️ <https://github.com/nookery>
