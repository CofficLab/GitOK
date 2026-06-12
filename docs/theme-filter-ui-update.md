# 主题选择器筛选功能更新

## 概述

为 GitOK 的主题状态栏插件添加了主题筛选功能，用户现在可以按明暗模式类型快速筛选主题。

## 更新内容

### 1. 筛选Tab

在主题选择器顶部添加了4个筛选Tab：

#### All（全部）

- 图标: `square.grid.2x2`
- 显示所有主题
- 显示主题总数

#### Dark（暗色）

- 图标: `moon.fill`
- 仅显示 `appearanceKind = .dark` 的主题
- 显示暗色主题数量

#### Light（亮色）

- 图标: `sun.max.fill`
- 仅显示 `appearanceKind = .light` 的主题
- 显示亮色主题数量

#### Adaptive（自适应）

- 图标: `circle.lefthalf.filled`
- 仅显示 `appearanceKind = .system` 的主题
- 显示自适应主题数量

### 2. 主题类型标记

每个主题名称旁边添加了小图标，快速识别主题类型：

- 🌙 **暗色主题** - 紫色月亮图标
- ☀️ **亮色主题** - 橙色太阳图标
- ◐ **自适应主题** - 蓝色半圆图标

### 3. 空状态提示

当筛选条件下没有主题时，显示友好的提示信息：

- "No dark themes"
- "No light themes"
- "No adaptive themes"

## UI设计

### 筛选Tab样式

```swift
// 选中状态
- 背景: Color.accentColor
- 文本颜色: .white
- 字重: .semibold

// 未选中状态
- 背景: 透明
- 边框: Color.secondary.opacity(0.2)
- 文本颜色: .primary
- 字重: .medium
```

### 主题类型徽章

```swift
case .dark:
    Image(systemName: "moon.fill")
        .foregroundColor(.purple.opacity(0.7))

case .light:
    Image(systemName: "sun.max.fill")
        .foregroundColor(.orange.opacity(0.7))

case .system:
    Image(systemName: "circle.lefthalf.filled")
        .foregroundColor(.blue.opacity(0.7))
```

## 实现细节

### 状态管理

使用 `@State` 管理当前选中的筛选条件：

```swift
@State private var selectedFilter: ThemeAppearanceKind? = nil
```

- `nil` = 显示全部主题
- `.dark` = 只显示暗色主题
- `.light` = 只显示亮色主题
- `.system` = 只显示自适应主题

### 主题筛选逻辑

```swift
private var filteredThemes: [GitOKUIThemeContribution] {
    guard let filter = selectedFilter else {
        return registry.themes
    }
    return registry.themes.filter { $0.chromeTheme.appearanceKind == filter }
}
```

### 动态计数

每个Tab显示对应类型的主题数量：

```swift
count: registry.themes.filter { $0.chromeTheme.appearanceKind == .dark }.count
```

## 用户体验

### 默认视图

- 显示所有主题
- "All" Tab 被选中

### 筛选操作

1. 点击任意筛选Tab
2. 列表立即更新，只显示对应类型的主题
3. 空状态时显示友好提示

### 视觉反馈

- Tab选中状态清晰可见
- 主题类型图标易于识别
- 主题数量实时显示

## 布局调整

由于添加了筛选Tab，将弹窗高度从 `420` 增加到 `460`：

```swift
.frame(height: 460)
```

## 文件修改

### 修改的文件

- `GitOK/Plugins/ThemeStatusBarPlugin/Sources/ThemePickerPopover.swift`

### 新增代码

1. `@State private var selectedFilter` - 筛选状态
2. `filteredThemes` - 计算属性
3. `filterTabs` - 筛选Tab UI
4. `filterTab()` - 单个Tab构建方法
5. `filterLabel()` - 标签文本辅助方法
6. `appearanceBadge()` - 主题类型徽章

## 主题统计

当前GitOK主题分布：

| 类型             | 数量   | 占比     |
| ---------------- | ------ | -------- |
| 暗色 (.dark)     | 14     | 70%      |
| 亮色 (.light)    | 5      | 25%      |
| 自适应 (.system) | 1      | 5%       |
| **总计**         | **20** | **100%** |

## 未来优化

### 短期

- [ ] 记住用户上次选择的筛选条件
- [ ] 添加搜索功能
- [ ] 支持按颜色系列筛选

### 长期

- [ ] 主题预览功能
- [ ] 主题收藏功能
- [ ] 自定义主题排序

## 技术要点

### 响应式设计

- Tab按钮使用固定布局，适配不同语言
- 主题数量动态计算，无需手动维护

### 性能优化

- 使用 `LazyVStack` 延迟加载主题列表
- 筛选操作O(n)复杂度，性能良好

### 可维护性

- 筛选逻辑集中在 `filteredThemes` 计算属性
- Tab配置清晰，易于扩展

## 测试建议

### 功能测试

1. ✅ 点击每个Tab，验证筛选正确
2. ✅ 验证主题数量显示正确
3. ✅ 验证主题类型徽章显示
4. ✅ 验证空状态提示

### UI测试

1. ✅ Tab选中状态样式
2. ✅ 主题列表布局
3. ✅ 不同屏幕尺寸下的显示

### 边界测试

1. ✅ 没有主题时的显示
2. ✅ 只有一种类型主题时的显示
3. ✅ 大量主题时的滚动性能

## 截图说明

### 默认视图（All Tab）

```
┌──────────────────────────────────────┐
│ 🎨 Theme                             │
├──────────────────────────────────────┤
│ [All 20] Dark 14  Light 5  Adaptive 1│
├──────────────────────────────────────┤
│ 📦 GitOK 默认 🌙                     │
│ 📦 Aurora 🌙                          │
│ 📦 Dracula 🌙                         │
│ ...                                  │
└──────────────────────────────────────┘
```

### 暗色主题筛选

```
┌──────────────────────────────────────┐
│ 🎨 Theme                             │
├──────────────────────────────────────┤
│ All 20  [Dark 14] Light 5  Adaptive 1│
├──────────────────────────────────────┤
│ 📦 GitOK 默认 🌙                     │
│ 📦 Aurora 🌙                          │
│ 📦 Dracula 🌙                         │
│ ...（仅显示暗色主题）                 │
└──────────────────────────────────────┘
```

### 自适应主题筛选

```
┌──────────────────────────────────────┐
│ 🎨 Theme                             │
├──────────────────────────────────────┤
│ All 20  Dark 14  Light 5  [Adaptive 1]│
├──────────────────────────────────────┤
│ 📦 GitOK 自适应 ◐                    │
└──────────────────────────────────────┘
```

## 总结

这次更新大幅提升了主题选择器的易用性：

✅ 快速筛选不同类型的主题  
✅ 直观显示主题类型和数量  
✅ 清晰的视觉反馈和状态  
✅ 保持代码简洁和可维护

用户现在可以更方便地浏览和选择适合自己需求的主题！

---

**更新日期:** 2026-06-09  
**版本:** 1.1.0  
**关联更新:** Theme Appearance Design v1.0.0
