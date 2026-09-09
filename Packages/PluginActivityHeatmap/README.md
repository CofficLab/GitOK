# PluginActivityHeatmap

数据插件：实现 `ProviderActivityHeatmap`，读取当前仓库所有 refs 最近一年的本地 Git 提交，按日期聚合，并将每个仓库的快照缓存到本插件自己的数据目录。首次没有缓存时通过 `isLoading` 发布进度，让消费方可以展示友好的 loading；已有缓存时保留旧图并静默后台刷新。它不包含 SwiftUI，Worktree Clean 等 UI 插件通过 `ActivityHeatmapProviding` 读取数据。
