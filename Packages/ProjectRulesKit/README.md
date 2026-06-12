# ProjectRulesKit

ProjectRulesKit 是 GitOK 的项目规则引擎库，集中管理各类项目相关的业务规则与决策逻辑，保持 App 层代码的简洁。

## 功能特性

- **Banner 存储规则**：Banner 数据的存储路径与命名规范
- **Commit 自动补全规则**：提交信息的自动补全策略
- **Auto Push 决策**：自动推送的触发条件与分支匹配
- **Commit Graph 布局规则**：提交图的渲染布局算法参数
- **项目事件刷新规则**：项目状态变更时的刷新策略
- **Avatar 身份规则**：用户头像的解析与缓存规则
- **远程仓库表单规则**：添加远程仓库时的表单校验
- **Banner 模板选择规则**：Banner 模板的推荐与筛选逻辑
- **图标文件规则**：项目图标文件的查找与回退策略
- **项目选择器规则**：项目列表的排序与过滤逻辑

## 系统要求

- macOS 14.0+
- Swift 6.0+

## 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "../ProjectRulesKit")
]
```

## 构建

```bash
swift build
```

## 测试

```bash
swift test
```

## Maintainers

Work for Joy & Live for Love ➡️ <https://github.com/nookery>
