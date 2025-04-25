# UI 设计规范

本文档定义了项目的UI设计规范，所有开发者在进行UI开发时都应当遵循这些规范，以确保整个应用的视觉一致性和用户体验。

## 核心原则

1. **组件优先**：优先使用DaisyUI提供的组件，避免重复造轮子
2. **一致性**：保持视觉元素的一致性，包括颜色、间距、圆角等
3. **响应式**：确保UI在不同尺寸的设备上都能良好展示
4. **主题支持**：支持DaisyUI的主题切换功能，不硬编码颜色值

## 组件使用规范

### DaisyUI 组件优先

- 优先使用DaisyUI提供的组件，如按钮、卡片、警告框等
- 使用DaisyUI的类名来定义组件样式，如`btn`、`card`、`alert`等
- 利用DaisyUI的变体来表达不同状态，如`btn-primary`、`btn-ghost`等
- 示例：

```html
<!-- 推荐：使用DaisyUI按钮 -->
<button class="btn btn-primary">确认</button>

<!-- 不推荐：自定义按钮样式 -->
<button class="px-4 py-2 bg-blue-500 text-white hover:bg-blue-600">确认</button>
```

### Tailwind CSS 精细调整

- 在DaisyUI组件不能满足需求时，使用Tailwind CSS进行精细化调整
- 使用Tailwind的工具类来调整间距、对齐、颜色等细节
- 遵循项目已有的设计风格，保持一致性
- 示例：

```html
<!-- DaisyUI组件 + Tailwind调整 -->
<div class="card card-compact w-full md:w-64 shadow-md hover:shadow-lg transition-all duration-300">
  <div class="card-body gap-2">
    <h2 class="card-title text-lg font-medium">卡片标题</h2>
    <p class="text-sm text-base-content/70">卡片内容描述</p>
  </div>
</div>
```

## 视觉规范

### 圆角大小

- 所有组件的圆角大小统一使用 `rounded-md`
- 特殊情况下可以使用其他圆角大小，但需要保持视觉一致性
- 示例：

```html
<!-- 推荐：使用统一的圆角大小 -->
<div class="p-4 bg-base-200 rounded-md">
  内容区域
</div>

<!-- 按钮也使用相同的圆角 -->
<button class="btn rounded-md">按钮</button>
```

### 颜色使用

- 不要硬编码颜色值，使用DaisyUI的主题颜色变量
- 使用语义化的颜色名称，如`primary`、`secondary`、`accent`等
- 使用透明度来创建不同的视觉层次，如`bg-primary/10`
- 示例：

```html
<!-- 推荐：使用主题颜色 -->
<div class="bg-primary text-primary-content">主要颜色区域</div>
<div class="bg-secondary/20">次要颜色区域（20%透明度）</div>

<!-- 不推荐：硬编码颜色 -->
<div class="bg-[#3b82f6] text-white">蓝色区域</div>
```

### 间距和尺寸

- 使用Tailwind的间距系统，保持一致的间距比例
- 常用间距：`p-4`（内边距）、`m-2`（外边距）、`gap-3`（间隙）
- 响应式设计中使用断点前缀，如`md:p-6`

## 最佳实践

1. **组件封装**：将常用的UI模式封装为Vue组件，提高复用性
2. **响应式设计**：使用Tailwind的断点前缀设计响应式界面
3. **主题适配**：确保UI在不同主题下都有良好的可读性和对比度
4. **无障碍性**：关注键盘导航、屏幕阅读器兼容性等无障碍特性
5. **性能优化**：避免过度使用复杂的CSS效果，注意性能影响

## 示例组件

项目中已有的组件可以作为参考：

- `Button.vue`：基于DaisyUI的按钮组件，支持多种变体和状态
- `Card.vue`：卡片布局组件，支持不同的变体和内容布局
- `Alert.vue`：警告提示组件，支持多种状态和关闭功能
- `Toast.vue`：轻量级消息提示组件，支持自动消失功能

遵循这些规范将帮助我们创建一个视觉一致、用户友好的界面，同时提高开发效率和代码可维护性。