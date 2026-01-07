# MARK 分组检查指令

## 重要规则

仅执行指令，无需进行总结。

## 步骤

1. 按照 [Swift 文件 MARK 分组规范](.cursor/rules/swift-mark-rule.mdc) 的要求检查文档，修复不规范的地方

## 检查要点

### 1. 分组顺序验证
确保文件中的分组顺序符合规范：
1. `// MARK: - Action`（用户交互触发的行为）
2. `// MARK: - Setter`（状态/属性的集中更新方法）
3. `// MARK: - Event Handler`（订阅通知、Combine 流、回调等）
4. `// MARK: - Preview`（文件结尾处的预览）

### 2. 扩展分组
使用 `extension TypeName { ... }` 将不同分组的函数隔离，提升可读性和导航效率。

### 3. 分组命名规范
- 使用英文分组名
- 首字母大写，短横线风格：`// MARK: - Action`
- 可选分组：`// MARK: - Init & Life Cycle`、`// MARK: - Private Helpers`、`// MARK: - Types`

### 4. 预览代码
确保文件结尾包含标准预览代码，遵循预览规则规范。

### 5. 函数语义
- Action 分组：使用主动语态动词，如 `refresh()`, `delete(at:)`
- Event Handler 分组：使用 `onXxx`/`handleXxx` 命名
- Setter 分组：使用 `@MainActor` 确保 UI 线程安全
