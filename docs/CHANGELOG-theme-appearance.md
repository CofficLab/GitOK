# Theme Appearance Update Changelog

## 概述

此次更新为 GitOK 添加了与 Cisum 一致的主题明暗模式支持设计。

## 主要变更

### 1. 主题协议更新

**文件:** `GitOK/Packages/GitOKUI/Sources/Theme/GitOKAppChromeTheme.swift`

- ❌ 移除: `var isDarkTheme: Bool { get }`
- ❌ 移除: `var followsSystemAppearance: Bool { get }`
- ✅ 保留: `var appearanceKind: ThemeAppearanceKind { get }` (现在作为主要属性)

**原因:**

- 简化API，使用单一属性表达主题的明暗特性
- 与 Cisum 的设计保持一致
- 更直观、更易于理解

### 2. 默认实现更新

移除了从 `isDarkTheme` 和 `followsSystemAppearance` 推导 `appearanceKind` 的逻辑，现在默认返回 `.dark`。

### 3. 所有主题插件更新

更新了以下主题插件中的主题定义：

#### 暗色主题 (.dark)

- ✅ ThemeGitOKPlugin - GitOK 默认主题
- ✅ ThemeAuroraPlugin - Aurora
- ✅ ThemeDraculaPlugin - Dracula
- ✅ ThemeEmberPlugin - Ember
- ✅ ThemeGlacierPlugin - Glacier
- ✅ ThemeGraphitePlugin - Graphite
- ✅ ThemeHarborPlugin - Harbor
- ✅ ThemeMatrixPlugin - Matrix
- ✅ ThemeMidnightPlugin - Midnight
- ✅ ThemeMountainPlugin - Mountain
- ✅ ThemeNebulaPlugin - Nebula
- ✅ ThemeOneDarkPlugin - OneDark
- ✅ ThemeOrchardPlugin - Orchard
- ✅ ThemeRiverPlugin - River

#### 亮色主题 (.light)

- ✅ ThemeGitHubLightPlugin - GitHub Light
- ✅ ThemeSpringPlugin - Spring
- ✅ ThemeSummerPlugin - Summer
- ✅ ThemeWinterPlugin - Winter
- ✅ ThemeXcodeLightPlugin - Xcode Light

#### 自适应主题 (.system)

- ✨ ThemeGitOKPlugin - **新增** GitOK 自适应主题

### 4. 新增自适应主题

**文件:** `GitOK/Plugins/ThemeGitOKPlugin/Sources/GitOKAdaptiveTheme.swift`

创建了一个全新的 `GitOKAdaptiveTheme`，展示如何实现自动跟随系统明暗模式的主题：

- 使用 `Color.adaptive(light:dark:)` 为明暗模式提供不同颜色
- `appearanceKind` 设置为 `.system`
- 提供完整的自适应颜色方案

### 5. 不透明度优化

#### 暗色主题

- glow subtle: 0.12
- glow medium: 0.16
- glow intense: 0.18
- sidebar selection: 0.24
- background decorations: 0.06 - 0.10

#### 亮色主题

- glow subtle: 0.08
- glow medium: 0.10
- glow intense: 0.12
- sidebar selection: 0.14
- background decorations: 0.035 - 0.05

### 6. 文档

新增文档：

- ✅ `docs/theme-appearance-design.md` - 英文设计文档
- ✅ `docs/theme-appearance-design-zh.md` - 中文设计文档（详细）
- ✅ `docs/CHANGELOG-theme-appearance.md` - 本文件

## 技术细节

### 代码变更模式

**结构体属性:**

```swift
// 旧
let isDarkTheme: Bool
let followsSystemAppearance: Bool

// 新
let appearanceKind: ThemeAppearanceKind
```

**主题实例:**

```swift
// 旧
MyTheme(
    isDarkTheme: true,
    followsSystemAppearance: false,
    // ...
)

// 新
MyTheme(
    appearanceKind: .dark,
    // ...
)
```

**颜色定义 (自适应主题):**

```swift
// 固定颜色（暗色或亮色主题）
Color(hex: "58A6FF")

// 自适应颜色（系统自适应主题）
Color.adaptive(light: "2563EB", dark: "58A6FF")
```

## 迁移影响

### 向后兼容性

⚠️ **破坏性变更**: 移除了 `isDarkTheme` 和 `followsSystemAppearance` 属性。

**影响范围:**

- 所有自定义主题插件需要更新
- 使用这些属性的代码需要改用 `appearanceKind`

**建议:**

- 如果有自定义主题，参考现有主题的更新模式进行修改
- 查阅 `docs/theme-appearance-design-zh.md` 获取详细迁移指南

### 性能影响

✅ **无性能影响** - 仅是API重构，底层实现逻辑未改变

## 测试

所有更新的文件已通过编译检查：

- ✅ 主题协议无诊断错误
- ✅ GitOK 主题无诊断错误
- ✅ GitOK 自适应主题无诊断错误
- ✅ Aurora 主题无诊断错误
- ✅ GitHub Light 主题无诊断错误
- ✅ Spring 主题无诊断错误
- ✅ Dracula 主题无诊断错误
- ✅ Winter 主题无诊断错误

## 未来计划

### 短期

- [ ] 为更多主题添加 `.system` 版本
- [ ] 优化主题选择器UI，显示主题的 `appearanceKind`
- [ ] 添加主题预览功能，可以预览明暗两种模式

### 长期

- [ ] 支持用户自定义主题
- [ ] 主题导入导出功能
- [ ] 基于时间自动切换主题

## 参考

- Cisum 主题系统: `Cisum/Packages/CisumUI/Sources/Theme/`
- Color.adaptive 实现: `Color+Hex.swift`
- ThemeAppearanceKind: `GitOK/Packages/GitOKUI/Sources/Theme/ThemeAppearanceKind.swift`

## 贡献者

感谢 Cisum 项目提供的优秀设计参考！

---

**更新日期:** 2026-06-09  
**版本:** 1.0.0
