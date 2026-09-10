# 项目编程语言 Provider 设计

## 背景

WorktreeClean 需要展示类似 GitHub 的项目编程语言占比。语言识别、文件遍历和字节统计属于较重的项目分析逻辑，不应由界面插件直接承担。

## 决策

- `ProviderProjectLanguages` 只定义稳定的数据模型和 `ProjectLanguagesProviding` 能力契约。
- `PluginProjectLanguages` 负责具体实现：读取当前项目 `HEAD` 的跟踪文件，识别常见语言并按文件字节数聚合。
- `PluginWorktreeClean` 只通过 Kernel 解析 `ProjectLanguagesProviding`，再用轻量适配器把快照映射为 SwiftUI 状态和视图。
- Provider 使用快照 + 观察者事件，允许未来替换为 GitHub API、语言服务或缓存实现，而不改动 WorktreeClean UI。

## 数据与刷新

分析结果按字节数降序排列，视图展示前六种语言，其余合并为“其他”。项目切换、项目数据变化和 Git 引用变化时触发刷新；异步刷新使用 token 丢弃过期结果。

干净工作区的结果会写入插件自己的磁盘缓存，缓存键由项目路径、`HEAD` hash 和分析器版本组成。刷新时先校验工作区状态并尝试读取缓存；脏工作区不复用或写入缓存，避免工作区文件大小变化造成错误占比。

## 取舍与失败处理

- 当前实现基于本地工作区文件大小，无法读取或识别的文件会被跳过，不阻塞整个项目页面。
- 常见生成目录和依赖目录会被排除，避免构建产物影响占比。
- 没有可用项目、尚未完成分析或结果为空时，UI 分别保持隐藏、显示加载态或不显示语言条。

## 验证

- Provider 快照排序和占比计算有单元测试。
- 分析器覆盖语言识别、目录排除和字节聚合。
- WorktreeClean、FactoryGitOK 及完整 GitOK Debug 构建均需通过。
