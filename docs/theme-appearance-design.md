# GitOK 主题明暗模式设计

## 概述

GitOK 现在支持三种主题外观模式，与 Cisum 的设计保持一致：

- **`.dark`** - 仅支持暗色模式
- **`.light`** - 仅支持亮色模式
- **`.system`** - 自动适配系统明暗模式

## 主题协议更新

### 旧设计

之前使用两个布尔值来控制主题外观：

```swift
public protocol GitOKAppChromeTheme {
    var isDarkTheme: Bool { get }
    var followsSystemAppearance: Bool { get }
    // ...
}
```

### 新设计

现在使用单一的 `appearanceKind` 属性：

```swift
public protocol GitOKAppChromeTheme {
    var appearanceKind: ThemeAppearanceKind { get }
    // ...
}

public enum ThemeAppearanceKind: String, CaseIterable {
    case dark   // 仅暗色
    case light  // 仅亮色
    case system // 自动适配
}
```

## 创建支持系统自动适配的主题

### 使用 Color.adaptive

对于 `.system` 主题，需要使用 `Color.adaptive(light:dark:)` 为明暗模式提供不同的颜色值：

```swift
struct AdaptiveTheme: GitOKAppChromeTheme {
    let appearanceKind: ThemeAppearanceKind = .system

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

    // ...
}
```

### 示例：GitOK 自适应主题

参考 `GitOKAdaptiveTheme` 实现，它提供了完整的系统自动适配示例。

## 固定明暗模式主题

### 暗色主题

对于仅支持暗色的主题：

```swift
struct DarkTheme: GitOKAppChromeTheme {
    let appearanceKind: ThemeAppearanceKind = .dark

    // 使用暗色配色方案
    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            Color(hex: "58A6FF"),
            Color(hex: "3FB950"),
            Color(hex: "BC8CFF")
        )
    }

    // 暗色模式的不透明度值
    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            primary.opacity(0.12),
            secondary.opacity(0.16),
            tertiary.opacity(0.18)
        )
    }
}
```

### 亮色主题

对于仅支持亮色的主题：

```swift
struct LightTheme: GitOKAppChromeTheme {
    let appearanceKind: ThemeAppearanceKind = .light

    // 使用亮色配色方案
    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            Color(hex: "2563EB"),
            Color(hex: "059669"),
            Color(hex: "7C3AED")
        )
    }

    // 亮色模式的不透明度值（通常较低）
    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            primary.opacity(0.08),
            secondary.opacity(0.10),
            tertiary.opacity(0.12)
        )
    }
}
```

## 不透明度建议

### 暗色主题

- glow subtle: 0.12
- glow medium: 0.16
- glow intense: 0.18
- sidebar selection: 0.24
- background decorations: 0.06 - 0.10

### 亮色主题

- glow subtle: 0.08
- glow medium: 0.10
- glow intense: 0.12
- sidebar selection: 0.14
- background decorations: 0.035 - 0.05

## 迁移指南

### 从旧API迁移

1. 移除 `isDarkTheme` 和 `followsSystemAppearance` 属性
2. 添加 `appearanceKind` 属性
3. 根据主题类型设置值：
   - 暗色主题: `.dark`
   - 亮色主题: `.light`
   - 自适应主题: `.system`

### 示例迁移

**旧代码:**

```swift
struct MyTheme: GitOKAppChromeTheme {
    let isDarkTheme = true
    let followsSystemAppearance = false
}
```

**新代码:**

```swift
struct MyTheme: GitOKAppChromeTheme {
    let appearanceKind: ThemeAppearanceKind = .dark
}
```

## 现有主题

### 暗色主题 (.dark)

- GitOK (默认)
- Aurora
- Dracula
- Ember
- Glacier
- Graphite
- Harbor
- Matrix
- Midnight
- Mountain
- Nebula
- OneDark
- Orchard
- River

### 亮色主题 (.light)

- GitHub Light
- Spring
- Summer
- Winter
- Xcode Light

### 自适应主题 (.system)

- GitOK 自适应 (新增)

## 参考

- Cisum 主题实现: `Cisum/Plugins/Theme*/Sources/*.swift`
- GitOK UI 主题协议: `GitOK/Packages/GitOKUI/Sources/Theme/GitOKAppChromeTheme.swift`
- ThemeAppearanceKind 枚举: `GitOK/Packages/GitOKUI/Sources/Theme/ThemeAppearanceKind.swift`
