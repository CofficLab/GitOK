# 预览代码检查指令

## 重要规则

仅执行指令，无需进行总结。

## 步骤

1. 按照 [Swift 文件预览代码规则](.cursor/rules/swift-preview-rule.mdc) 的要求检查文档，修复不规范的地方

## 检查要点

### 1. 预览代码存在性
检查每个 Swift 文件是否在结尾包含标准的预览代码：
```swift
#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
```

### 2. 预览代码位置
- **必须在文件结尾**：预览代码应放在文件的最后部分
- **在所有其他代码之后**：包括所有 extension 和辅助代码之后

### 3. 预览配置规范
#### 小屏幕预览
- **标题**：`"App - Small Screen"`
- **宽度**：约 800px
- **高度**：约 600px
- **隐藏元素**：侧边栏 + 项目操作（`.hideSidebar().hideProjectActions()`）

#### 大屏幕预览
- **标题**：`"App - Big Screen"`
- **宽度**：约 1200px
- **高度**：约 1200px
- **隐藏元素**：仅侧边栏（`.hideSidebar()`）

### 4. 预览代码格式
- **使用 `#Preview` 宏**：而不是 `#if os(macOS)` 包装
- **正确的缩进**：保持代码整洁和一致的缩进
- **空行分隔**：两个预览之间用空行分隔

### 5. 预览适用性
#### 需要预览的文件
- **UI 组件文件**：包含 View struct 的 Swift 文件
- **主要功能模块**：影响 UI 显示的逻辑文件
- **工具类文件**：如果包含可预览的 UI 相关功能

#### 无需预览的文件
- **纯数据模型**：如 `Project.swift`、`GitCommit.swift` 等
- **纯工具类**：如 `ShellGit.swift`、`MagicCore` 扩展
- **协议定义**：如 `SuperLog.swift`、`SuperEvent.swift`
- **测试文件**：单元测试和 UI 测试文件

### 6. 预览内容验证
- **ContentLayout 使用**：确保使用标准的 `ContentLayout()` 作为预览根视图
- **RootView 包装**：使用 `.inRootView()` 确保正确的环境
- **合理的尺寸**：尺寸应适合对应的屏幕类型
- **功能完整性**：预览应展示组件的主要功能和状态

### 7. 特殊情况处理
#### 条件编译预览
某些文件可能需要条件编译的预览：
```swift
#if os(macOS)
#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
#endif

#if os(iOS)
#Preview("iPhone") {
    ContentLayout()
        .inRootView()
}
#endif
```

#### 自定义预览内容
对于特殊组件，可能需要自定义预览内容而非标准模板，但仍需遵循命名和结构规范。

### 8. 预览更新维护
- **同步更新**：当组件接口变化时，及时更新对应的预览
- **测试覆盖**：确保预览涵盖主要使用场景
- **性能考虑**：避免在预览中进行耗时操作或网络请求
