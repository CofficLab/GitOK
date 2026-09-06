# PluginGitCLI

Git CLI 后端插件：将当前 `KitGit` 的系统 `git` 实现注册到 `ProviderGit` 的稳定路由器。

业务插件只应依赖 `GitProviding`，不应直接依赖本插件或 `GitCLIBackend`。后续
`PluginGitLibGit2` 可以实现同一 `GitBackendProviding`，由用户选择启用的后端。

```bash
swift test
```
