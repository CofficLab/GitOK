# PluginGitCLI

Git CLI 后备插件：将当前 `KitGit` 的系统 `git` 实现注册到 `ProviderGit` 的稳定路由器；LibGit2Swift 不支持的操作会回退到此后端。

业务插件只应依赖 `GitProviding`，不应直接依赖本插件或 `GitCLIBackend`。LibGit2Swift 是默认优先后端，CLI 作为兼容备选。

```bash
swift test
```
