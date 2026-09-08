# PluginActivityHeatmap

数据插件：实现 `ProviderActivityHeatmap`，读取当前仓库最近六个月的本地 Git 提交，按日期聚合，并将每个仓库的快照缓存到本插件自己的数据目录。首次计算或后台刷新期间通过 `isLoading` 发布进度，让消费方可以展示友好的 loading；它不包含 SwiftUI，Worktree Clean 等 UI 插件通过 `ActivityHeatmapProviding` 读取数据。
