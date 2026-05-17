# Push Behind Remote TODO

目标：参考 GitHub Desktop 的处理方式，让 GitOK 在“本地分支落后远程，同时本地又有新提交”时给出明确、可恢复的工作流。

## 设计原则

- 不在 push 失败后自动 pull、merge 或 rebase。
- 状态已知时，用按钮状态提前引导用户先 Pull/Fetch。
- 状态未知时，允许 push 失败，但将 non-fast-forward 映射为专门提示。
- Fetch 是安全操作，可以作为 push 失败后的默认下一步。

## TODO

- [x] 1. 增加本方案 TODO 文档。
- [x] 2. 增加底层 Git fetch 能力。
  - 在 `GitRepositoryCLI` 增加 `fetch(remote:)`。
  - 在 `Project` 增加 `fetch()` 并发送 `projectDidFetch` 事件。

- [x] 3. 增加 ahead/behind 查询能力。
  - 新增 `GitAheadBehind` 数据结构。
  - 使用 `git rev-list --left-right --count HEAD...@{upstream}` 查询当前分支与 upstream 的差异。
  - 没有 upstream 时返回未发布状态，而不是报通用错误。

- [x] 4. 在 `ProjectVM` 暴露远端差异状态。
  - 增加 `aheadCount`、`behindCount`、`hasUpstream`、`lastFetchedAt`。
  - 项目切换、commit、push、pull、fetch、branch change 后刷新。

- [x] 5. 改造 Push 按钮状态。
  - `behind > 0` 时主操作显示 Pull，而不是 Push。
  - `ahead > 0 && behind == 0` 时显示 Push。
  - `ahead == 0 && behind == 0` 时显示 Fetch 或空闲状态。
  - 无 upstream 时显示 Publish Branch/设置 upstream 的后续入口。

- [x] 6. 捕获 push non-fast-forward。
  - 将 `non-fast-forward`、`fetch first`、`failed to push some refs` 等错误识别为 `pushNeedsFetch`。
  - 不再只显示通用错误。

- [x] 7. 增加 PushNeedsPull/Fetch 提示。
  - 标题：`远程有新的提交`。
  - 正文：说明远程包含本地没有的提交，需要先 Fetch，再 Pull/Rebase 后 Push。
  - 主按钮：`Fetch`。
  - 第一版不自动 Pull/Rebase。

- [x] 8. 修正 Sync 顺序。
  - 先 Fetch。
  - 再根据 ahead/behind 决定 Pull 或 Push。
  - 当 ahead 和 behind 都大于 0 时，不静默处理，提示用户选择 Pull/Rebase。

## 当前进度

- 总进度：8/8
- 状态：已完成，已通过 `swift test` 和 `xcodebuild -scheme GitOK -destination 'platform=macOS' build`
