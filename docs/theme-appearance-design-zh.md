# GitOK 主题明暗模式设计

## 概述

GitOK 现已支持三种主题外观模式，与 Cisum 的设计保持一致：

- **`.dark`** - 仅支持暗色模式（深色主题）
- **`.light`** - 仅支持亮色模式（浅色主题）
- **`.system`** - 自动适配系统明暗模式

## 设计理念

### 为什么需要明暗模式区分？

不同的主题有不同的使用场景：

1. **暗色主题** - 适合夜间或低光环境，减少眼睛疲劳
2. **亮色主题** - 适合白天办公，提供更好的对比度
3. **自适应主题** - 跟随系统设置自动切换，提供一致的用户体验

### 实现方式

通过 `appearanceKind` 属性明确标识主题的明暗支持：

```swift
public enum ThemeAppearanceKind: String, CaseIterable {
    case dark   // 仅暗色
    case light  // 仅亮色
    case system // 自动适配系统
}
```

## 主题协议变更

### 旧设计（已废弃）

```swift
public protocol GitOKAppChromeTheme {
    var isDarkTheme: Bool { get }
    var followsSystemAppearance: Bool { get }
}
```

问题：

- 两个布尔值的组合不够直观
- 需要通过计算属性推导 `appearanceKind`
- 与 Cisum 的设计不一致

### 新设计（推荐）

```swift
public protocol GitOKAppChromeTheme {
    var appearanceKind: ThemeAppearanceKind { get }
}
```

优势：

- 单一属性，语义清晰
- 直接表达主题的明暗特性
- 与 Cisum 设计统一

## 实现指南

### 1. 仅暗色主题 (.dark)

适合喜欢深色界面的用户，提供统一的暗色体验。

```swift
struct MyDarkTheme: GitOKAppChromeTheme {
    let identifier = "my-dark"
    let displayName = "我的暗色主题"
    let appearanceKind: ThemeAppearanceKind = .dark

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            Color(hex: "58A6FF"),  // 明亮的蓝色
            Color(hex: "3FB950"),  // 明亮的绿色
            Color(hex: "BC8CFF")   // 明亮的紫色
        )
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (
            Color(hex: "0D1117"),  // 最深的背景
            Color(hex: "161B22"),  // 中等背景
            Color(hex: "21262D")   // 较浅背景
        )
    }

    func workspaceTextColor() -> Color {
        Color(hex: "F0F6FC")  // 接近白色的文本
    }
}
```

**推荐不透明度值：**

- 发光效果: 0.12 - 0.18
- 选中项背景: 0.24
- 装饰元素: 0.06 - 0.10

### 2. 仅亮色主题 (.light)

适合白天办公环境，提供清晰的对比度。

```swift
struct MyLightTheme: GitOKAppChromeTheme {
    let identifier = "my-light"
    let displayName = "我的亮色主题"
    let appearanceKind: ThemeAppearanceKind = .light

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            Color(hex: "2563EB"),  // 较深的蓝色
            Color(hex: "059669"),  // 较深的绿色
            Color(hex: "7C3AED")   // 较深的紫色
        )
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (
            Color(hex: "F3F4F6"),  // 浅灰色背景
            Color(hex: "FFFFFF"),  // 纯白背景
            Color(hex: "E5E7EB")   // 更浅的灰色
        )
    }

    func workspaceTextColor() -> Color {
        Color(hex: "1F2937")  // 深灰色文本
    }

    func sidebarSelectionTextColor() -> Color {
        Color(hex: "111827")  // 选中项使用深色文本
    }
}
```

**推荐不透明度值：**

- 发光效果: 0.08 - 0.12
- 选中项背景: 0.14
- 装饰元素: 0.035 - 0.05

### 3. 自适应主题 (.system)

跟随系统设置自动在明暗模式间切换，提供最佳体验。

```swift
struct MyAdaptiveTheme: GitOKAppChromeTheme {
    let identifier = "my-adaptive"
    let displayName = "我的自适应主题"
    let appearanceKind: ThemeAppearanceKind = .system

    // 使用 Color.adaptive 为明暗模式提供不同的颜色
    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            .adaptive(light: "2563EB", dark: "58A6FF"),
            .adaptive(light: "059669", dark: "3FB950"),
            .adaptive(light: "7C3AED", dark: "BC8CFF")
        )
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (
            .adaptive(light: "F3F4F6", dark: "0D1117"),
            .adaptive(light: "FFFFFF", dark: "161B22"),
            .adaptive(light: "E5E7EB", dark: "21262D")
        )
    }

    func workspaceTextColor() -> Color {
        .adaptive(light: "1F2937", dark: "F0F6FC")
    }

    func workspaceSecondaryTextColor() -> Color {
        .adaptive(light: "6B7280", dark: "C9D1D9")
    }

    func workspaceTertiaryTextColor() -> Color {
        .adaptive(light: "9CA3AF", dark: "8B949E")
    }

    func sidebarSelectionTextColor() -> Color {
        .adaptive(light: "1F2937", dark: "FFFFFF")
    }
}
```

**关键点：**

- 所有颜色都必须使用 `Color.adaptive(light:dark:)`
- 明暗模式的不透明度可以保持一致，系统会自动调整效果
- 图标颜色也应该支持自适应

## Color.adaptive 工具方法

`Color.adaptive` 是一个便捷方法，用于创建支持明暗模式的颜色：

```swift
extension Color {
    static func adaptive(light: String, dark: String) -> Color {
        Color(light: Color(hex: light), dark: Color(hex: dark))
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
```

## 迁移现有主题

### 步骤 1: 更新属性定义

**旧代码：**

```swift
struct MyTheme: GitOKAppChromeTheme {
    let isDarkTheme: Bool
    let followsSystemAppearance: Bool
}
```

**新代码：**

```swift
struct MyTheme: GitOKAppChromeTheme {
    let appearanceKind: ThemeAppearanceKind
}
```

### 步骤 2: 更新主题实例

**旧代码：**

```swift
static let myTheme = MyTheme(
    isDarkTheme: true,
    followsSystemAppearance: false
)
```

**新代码：**

```swift
static let myTheme = MyTheme(
    appearanceKind: .dark
)
```

### 步骤 3: 调整不透明度（如果需要）

如果是亮色主题，确保使用较低的不透明度值以获得最佳视觉效果。

## 现有主题列表

### 暗色主题 (.dark)

| 主题名称   | identifier   | 特色                  |
| ---------- | ------------ | --------------------- |
| GitOK 默认 | repository   | GitHub 风格的深色主题 |
| Aurora     | commit-graph | 青色系夜间主题        |
| Dracula    | dracula      | 经典 Dracula 配色     |
| Ember      | ember        | 橙红色温暖主题        |
| Glacier    | glacier      | 冰蓝色冷色调          |
| Graphite   | graphite     | 灰色专业主题          |
| Harbor     | harbor       | 港湾蓝色主题          |
| Matrix     | matrix       | 绿色黑客风格          |
| Midnight   | midnight     | 深蓝午夜主题          |
| Mountain   | mountain     | 山峦灰色主题          |
| Nebula     | nebula       | 星云紫色主题          |
| OneDark    | one-dark     | Atom 编辑器风格       |
| Orchard    | orchard      | 果园绿色主题          |
| River      | river        | 河流蓝色主题          |

### 亮色主题 (.light)

| 主题名称     | identifier   | 特色            |
| ------------ | ------------ | --------------- |
| GitHub Light | github-light | GitHub 官方亮色 |
| Spring       | worktree     | 春日绿色主题    |
| Summer       | summer       | 夏日明亮主题    |
| Winter       | focus        | 冬日简洁主题    |
| Xcode Light  | xcode-light  | Xcode 风格亮色  |

### 自适应主题 (.system)

| 主题名称     | identifier     | 特色             |
| ------------ | -------------- | ---------------- |
| GitOK 自适应 | gitok-adaptive | 自动跟随系统设置 |

## 最佳实践

### 1. 命名规范

- 暗色主题建议使用夜间、深色相关的名称
- 亮色主题建议使用白天、明亮相关的名称
- 自适应主题建议在名称中体现"自适应"或"跟随系统"

### 2. 颜色选择

**暗色主题：**

- 背景使用深色（#0D1117 等）
- 强调色使用明亮、高饱和度的颜色
- 文本使用接近白色的颜色

**亮色主题：**

- 背景使用浅色或纯白（#FFFFFF）
- 强调色使用较深、中等饱和度的颜色
- 文本使用深灰或黑色

**自适应主题：**

- 确保明暗两种模式下都有良好的对比度
- 测试两种模式下的可读性

### 3. 可访问性

- 确保文本和背景有足够的对比度
- 测试色盲友好性
- 考虑不同光线条件下的可读性

### 4. 性能考虑

- 自适应主题会在系统切换时重新渲染
- 避免在颜色计算中进行复杂操作
- 缓存计算结果以提高性能

## 测试建议

### 测试暗色主题

1. 在暗色系统模式下查看
2. 检查所有UI元素的可见性
3. 验证强调色的对比度

### 测试亮色主题

1. 在亮色系统模式下查看
2. 确保在强光下仍然可读
3. 检查边框和分隔线的可见性

### 测试自适应主题

1. 在系统设置中切换明暗模式
2. 验证颜色过渡的平滑性
3. 确保两种模式下都有良好体验

## 参考资源

- [Human Interface Guidelines - Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [Material Design - Dark Theme](https://material.io/design/color/dark-theme.html)
- Cisum 主题实现: `Cisum/Plugins/Theme*/Sources/`
- GitOK 主题协议: `GitOK/Packages/GitOKUI/Sources/Theme/`

## 常见问题

### Q: 如何在自适应主题中处理图标颜色？

A: 使用 `Color.adaptive` 为图标提供明暗两种颜色：

```swift
let iconColor = Color.adaptive(light: "2563EB", dark: "58A6FF")
```

### Q: 可以在运行时切换主题的 appearanceKind 吗？

A: 不建议。`appearanceKind` 应该是主题的固定属性。如果需要切换明暗模式，应该切换到不同的主题。

### Q: 如何为自适应主题设置不同的不透明度？

A: 保持不透明度一致即可。系统会根据明暗模式自动调整视觉效果。如果确实需要不同值，可以在不透明度计算中使用环境值。

### Q: 旧主题会自动迁移吗？

A: 所有现有主题已经更新为新的 API。如果你有自定义主题，需要手动迁移。

## 总结

GitOK 的主题系统现在提供了更清晰、更一致的明暗模式支持：

✅ 单一 `appearanceKind` 属性，语义明确  
✅ 支持三种模式：dark、light、system  
✅ 与 Cisum 设计保持一致  
✅ 便于创建和维护主题  
✅ 良好的用户体验

开始创建你的第一个自适应主题吧！
