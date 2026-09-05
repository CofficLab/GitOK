# GitOK Git 能力恢复审计与执行步骤

## 1. 目标与对比基线

本文只关注 Git 相关能力，不处理 Banner、Icon、主题等非 Git 功能。

- 旧版基线：`v3.0.22`，commit `85b8aaac7953d96b4018c6d67541719a5fc9a068`
- 当前版本：`dev`，审计时 HEAD 为 `4aacbaea`
- 旧版核心入口：`Packages/GitCoreKit/Sources/GitRepositoryCLI.swift`
- 当前核心入口：`Packages/KitGit/Sources/KitGit/`
- 旧版插件注册：`Packages/GitOKPluginRegistry/Sources/GeneratedPluginRegistry.swift`
- 当前插件装配：`Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift`

这是一次架构迁移，不应只用“文件是否还存在”判断功能是否保留。旧插件已经被拆成多个新插件，例如：

| 旧版 | 当前候选替代 | 需要继续核实的内容 |
| --- | --- | --- |
| `GitCommitListPlugin` | `PluginCommitList` | 历史列表、分页、右键历史操作是否保留 |
| `GitDetailPlugin` | `PluginCommitDetail`、`PluginCommitForm`、`PluginGitDiff` | 文件操作、预览、暂存区工作流是否保留 |
| `GitWorkingStatePlugin` | `PluginWorktreeStatus`、`PluginWorktreeClean` | fetch/pull/push、认证、冲突和 stash-and-pull 是否保留 |
| `GitBranchPlugin` | `PluginGitBranchStatus` | rename、upstream、publish、compare、远程分支删除是否保留 |
| `GitMergePlugin` | `PluginGitSmartMerge` | 冲突后的继续/中止/逐文件处理是否保留 |
| `GitWatcherPlugin` | `PluginGitRepositoryWatch` | 外部 Git 变化是否能刷新所有消费者 |
| `GitCleanStatusPlugin` | `PluginWorktreeClean` | 干净状态和仓库信息是否仍可见 |
| `ProjectsPlugin`、`ProjectPickerPlugin` | `PluginProjects` | 新建仓库、导入、持久化和切换是否保留 |

## 2. 当前静态审计已经确认的缺口

下表中的“缺失”指当前代码中没有找到对应的底层 API 或 UI 操作链，不等于已经完成运行时验证。执行 agent 需要按本文后续步骤补充运行时证据。

### 2.1 底层 Git API 缺口

旧版 `GitRepositoryCLI` 在 `v3.0.22` 中提供了以下能力，而当前 `KitGit` 没有等价入口：

| 能力 | 旧版证据 | 当前静态结果 | 优先级 |
| --- | --- | --- | --- |
| 单文件/批量暂存、取消暂存、丢弃 | `addFiles`、`applyPatch`、`unstageFiles`、`discardFileChanges`、`discardAllChanges` | 当前只有 `GitCommitOperation.addAll`；`WorktreeChangesView` 只有选择文件和查看 diff | P0 |
| 历史操作 | `revertCommit`、`squashLastCommits`、`reset(...soft/mixed/hard)` | 当前没有对应 `KitGit` API，也没有当前提交列表右键菜单 | P0 |
| Tag 管理 | 创建轻量/附注 tag、删除本地 tag、推送/删除远程 tag | 当前没有对应 API/UI | P1 |
| 分支高级管理 | `renameBranch`、`setUpstream`、`unsetUpstream`、`publishBranch`、`deleteRemoteBranch` | 当前 `GitBranchOperation` 只有列出、新建、切换、删除本地分支 | P0 |
| 分支比较 | `compareBranches` 及 ahead/behind、commit/file 列表 | 当前没有对应 API/UI | P1 |
| Rebase | `rebaseStatus`、`startRebase`、`continueRebase`、`abortRebase` | 当前没有对应 API/UI | P1 |
| Cherry-pick | `cherryPickStatus`、`cherryPick`、`continueCherryPick`、`abortCherryPick` | 当前没有对应 API/UI | P1 |
| Merge 状态处理 | `mergeFileContent`、`mergeFileDiff`、`checkoutMergeFileVersion`、`continueMerge`、`abortMerge`、`finalizeMergeIfNeeded` | 当前 `GitMergeOperation` 只做 merge、检测冲突文件；没有解决动作 | P0 |
| 远程维护 | `updateRemote`，以及完整的 upstream/remote 分支处理 | 当前只有 list/add/remove/fetch/pull/push | P1 |
| 仓库初始化/创建 | `initialize`、`create`、README、`.gitignore`、LICENSE、初始提交选项 | 当前 `GitCloneOperation` 只支持 clone；项目页面只有添加已有目录和 clone | P1 |
| Clone 预处理和错误分类 | URL 规范化、仓库名推导、SSH host、目的地状态、认证/代理/证书/网络错误分类 | 当前只有基本目的地校验和默认仓库名 | P1 |
| SSH 配置解析 | `SSHConfigURLResolver.swift` | 当前 `KitGit` 没有对应文件或 API | P1 |
| LFS 完整检查 | LFS 可用性、初始化、大文件候选、attribute mismatch | 当前插件主要是可用性、大文件扫描和 `lfs install` | P2 |
| Submodule 完整操作 | 指定路径初始化/更新、submodule diff | 当前只有列表和全部更新 | P2 |

当前 `KitGit` 的核心限制可以直接从以下文件确认：

- `GitBranchOperation.swift`：只有 4 个分支操作。
- `GitRemoteOperation.swift`：没有 remote update、upstream 和 remote branch 写操作。
- `GitCommitOperation.swift`：只有 staged 检查、`add -A`、commit、push。
- `GitMergeOperation.swift`：只有 merge 和冲突检测。
- `GitSubmoduleOperation.swift`：只有 list 和 update-all。
- `GitDiffLoader.swift`：负责读取 diff，不负责文件内容、patch、暂存或丢弃。

### 2.2 已确认的 UI/交互缺口

1. 旧版 `Plugins/GitDetailPlugin/Sources/Detail/Views/FileBatchActionBarView.swift` 提供批量 Stage、Unstage、Discard、全选和清空选择；当前 `Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/WorktreeChangesView.swift` 只渲染文件列表并调用 `projects.selectFile`。
2. 旧版 `Plugins/GitDetailPlugin/Sources/Views/Row/CommitRowContextMenu.swift` 提供 Create Tag、Push/Delete Tag、Undo、Revert、Squash、Soft/Mixed/Hard Reset；当前 `Packages/PluginCommitList/Sources/PluginCommitList/Views/CommitRailView.swift` 目前只有提交列表和未推送 commit 的 push 入口。
3. 旧版 `GitBranchPlugin` 的管理页有 rename、set/unset upstream、publish、删除远程分支、compare、merge compare 结果和 Create PR；当前 `PluginGitBranchStatus` 管理页只有新建、切换、删除本地分支，远程分支只展示。
4. 旧版 `GitWorkingStatePlugin` 有 fetch、pull、push、stash-and-pull、认证输入、网络失败后的 SSH fallback、push 重试和冲突文件 stage/checkout ours/theirs/continue/abort；当前 `PluginWorktreeStatus` 只有基本 fetch/pull/push，`PluginGitConflictResolver` 只有冲突列表、复制路径和 Finder 定位。
5. 旧版 `CreateRepositorySheet` 可初始化本地仓库、选择 README/.gitignore/LICENSE 并创建初始提交；当前 `PluginProjects` 的空状态只提供 Add Project，`PluginCloneRepository` 只提供 Clone Repository。

### 2.3 集成层风险

当前 `project.yml` 仍包含：

```yaml
- target: GitOperationService
```

但当前工作区没有 `GitOperationService/` 目录；旧版的 `GitOperationService/main.swift` 和 `GitOperationService/Info.plist` 已被删除。与此同时，旧版 `GitCoreKit` 依赖 `LibGit2Swift`，当前 `KitGit` 改为直接执行系统 Git CLI。必须先确认这是有意移除还是迁移遗漏，否则后续功能恢复可能建立在一个无法可靠生成/构建的工程上。

## 3. 推荐的审计方法

### 步骤 0：冻结工作区和基线

不要在用户已有改动上直接生成工程或批量迁移。先记录状态：

```bash
git status --short --branch
git rev-parse HEAD
git rev-parse v3.0.22
git diff --stat
```

建议为旧版创建只读对比 worktree：

```bash
git worktree add --detach ../GitOK-v3.0.22 v3.0.22
```

所有旧版代码、测试和资源均优先从该 worktree 读取，不要把旧版文件直接覆盖到当前分支。

### 步骤 1：生成文件级迁移清单

先看 rename，而不是只看删除：

```bash
git diff --find-renames --find-copies --summary v3.0.22..HEAD
git diff --find-renames --find-copies --name-status v3.0.22..HEAD > /tmp/gitok-v3-to-current-name-status.txt
```

Git 范围过滤：

```bash
git diff --find-renames --find-copies --name-status v3.0.22..HEAD -- \
  'Packages/**' 'Plugins/**' 'GitOKApp/**' 'GitOperationService/**' \
  | rg -i 'git|commit|branch|stash|diff|clone|remote|worktree|conflict|ignore|submodule|lfs|project|open'
```

将结果分为四类：

- `移植且等价`：名称改变，但底层语义、入口、错误处理和刷新行为都存在。
- `移植但缩水`：有新文件，但只保留了旧功能的一部分。
- `只保留底层`：API 存在，但没有从 factory、plugin 或 UI 暴露。
- `完全缺失`：旧版有代码/测试，当前没有可追踪替代链路。

不要把“新文件存在”当成“功能恢复”。必须追踪到一个可点击入口和实际 Git 命令。

### 步骤 2：建立旧版能力目录

旧版先以行为为单位建表，不以文件为单位建表。最低限度应覆盖：

```bash
git grep -n -E 'public (static )?func|public (struct|enum|protocol|class)' \
  v3.0.22 -- Packages/GitCoreKit Plugins/Git*Plugin GitOKApp GitOperationService
```

然后重点阅读：

- `Packages/GitCoreKit/Sources/GitRepositoryCLI.swift`
- `Packages/GitCoreKit/Sources/GitModels.swift`
- `Packages/GitCoreKit/Sources/GitOperationError.swift`
- `Packages/GitCoreKit/Sources/GitOperationXPC.swift`
- `Plugins/GitDetailPlugin/Sources/Detail/Views/FileBatchActionBarView.swift`
- `Plugins/GitDetailPlugin/Sources/Views/Row/CommitRowContextMenu.swift`
- `Plugins/GitWorkingStatePlugin/Sources/Views/WorkingStateView.swift`
- `Plugins/GitBranchPlugin/Sources/Views/BranchManagementView.swift`
- `Packages/GitOKAppCore/Sources/GitOKAppCore/Views/CreateRepositorySheet.swift`

每个能力至少记录：旧入口、命令/API、输入、成功后的事件、失败提示、是否改变仓库、对应测试。

### 步骤 3：建立当前装配和调用链

当前从这里开始追踪：

```bash
sed -n '60,145p' Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift
rg -n 'Git(ProcessRunner|BranchOperation|RemoteOperation|CommitOperation|MergeOperation|StashOperation|SubmoduleOperation|CloneOperation)|GitConfigReader' \
  Packages --glob '!*/.build/**'
```

对每个旧能力逐层确认：

```text
UI button/menu
  -> plugin view/model
  -> Provider 或 ProjectProviding
  -> KitGit operation
  -> GitProcessRunner / git 命令
  -> 成功/失败事件
  -> commit list、worktree、diff、status 等消费者刷新
```

任一层断开，就标记为“未恢复”。特别检查：

- 插件是否真的在 `DefaultPluginFactory.makePlugins()` 中装配。
- `PluginMetadata.policy` 为 `.disabled` 时，宿主是否仍会启动该插件；不能只看插件文件存在。
- 写操作完成后是否调用 `ProjectProviding.notifyDataChanged()` 或等价事件。
- 外部终端修改 `.git` 后，列表、表单、diff、状态栏是否都刷新。
- 错误是否被 UI 显示，还是被 `try?` 静默吞掉。

### 步骤 4：核对工程生成和构建边界

先检查 `project.yml` 的路径是否都存在：

```bash
rg -n '^\s*- (path|target|package):' project.yml
test -d GitOperationService || echo 'GitOperationService missing'
```

在确认不会覆盖用户工程改动后，再决定是否执行：

```bash
xcodegen generate --spec project.yml
xcodebuild -list -project GitOK.xcodeproj
```

工程能生成只是最低条件。之后分别验证：

```bash
swift test --package-path Packages/KitGit
swift test --package-path Packages/PluginCommitList
swift test --package-path Packages/PluginCommitDetail
swift test --package-path Packages/PluginGitBranchStatus
swift test --package-path Packages/PluginGitConflictResolver
xcodebuild -project GitOK.xcodeproj -scheme GitOK -configuration Debug \
  -sdk macosx -derivedDataPath /tmp/GitOK-derived-data \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

不要把单个 package 编译成功写成完整 App 验证成功；也不要把 `xcodebuild` 尚未走到编译阶段的错误归因于 Git 功能代码。

## 4. 建议的恢复顺序

### P0：先恢复可用的基本工作区流程

1. 修复工程生成边界：确认删除 `GitOperationService`，还是恢复它；同步清理/更新 `project.yml` 和 target 依赖。
2. 在 `KitGit` 增加结构化状态模型和写操作：单文件/批量 stage、unstage、discard、discard all，并保留路径安全和错误输出。
3. 在当前工作区文件列表中恢复选择、全选、批量操作、确认弹窗和刷新事件。
4. 恢复 merge conflict 的 stage、ours/theirs、continue、abort；`PluginGitConflictResolver` 不能只展示文件名。
5. 恢复历史 commit 的 context menu：至少 Undo/Reset、Revert、Squash；每个危险操作都要有确认和 dirty-worktree 防护。

### P1：补齐 Git 日常管理

1. 分支 rename、upstream、publish、删除远程分支、branch compare。
2. 完善 fetch/pull/push 的认证提示、网络错误分类、SSH fallback、stash-and-pull 和重试。
3. 恢复本地仓库初始化/创建，并将 README、`.gitignore`、LICENSE、初始提交纳入可测试的 options。
4. 恢复 remote update、tag 创建/删除/推送，以及历史列表中的 tag 操作。
5. 恢复 rebase/cherry-pick 的状态检测、continue、abort；这些操作必须在刷新和错误状态上有专门测试。

### P2：补齐高级能力和体验

1. Submodule 指定路径操作和 diff。
2. LFS attribute mismatch、候选文件处理和更清晰的安装/认证提示。
3. 二进制/图片/大文件预览、文件内容读取、过滤、复制路径等旧版详情体验。
4. 完善分页、commit graph、远程 PR 链接和可访问性/本地化。

## 5. 测试夹具与验收矩阵

建议建立临时 Git fixture，而不是只在当前仓库上手工点击。至少准备：

```text
clean                  干净仓库
working-tree-changes   修改、未跟踪、删除、重命名
staged-and-unstaged    同一文件同时 staged + worktree modified
branches               两个本地分支、远程分支、upstream
remote                 本地 bare remote，用于 fetch/pull/push/publish
merge-conflict         可重复产生冲突，并可验证 ours/theirs/continue/abort
history                多个 commit、tag、merge commit
stash                  多个 stash，验证 save/apply/pop/drop/branch
submodule              初始化和未初始化的子模块
rebase-cherry-pick     可重复进入进行中状态的历史操作
```

每条能力都要记录以下结果：

| 字段 | 要求 |
| --- | --- |
| UI 入口 | 能从当前 App 找到按钮、菜单或设置项 |
| 底层命令 | 明确记录实际执行的 Git 命令和参数 |
| 状态变化 | 仓库状态改变后，哪些 provider/view 收到刷新事件 |
| 错误路径 | 认证、冲突、dirty worktree、无 upstream、网络失败如何显示 |
| 回归测试 | package 测试或 fixture 测试名称 |
| 手工验收 | 在真实 App 中完成一次成功和一次失败操作 |

建议把能力账本保存为 `docs/git-capability-matrix.md` 或 JSON，状态只允许使用：`verified`、`partial`、`missing`、`blocked`。`partial` 必须写明缺少哪一段链路，不能只写“基本可用”。

## 6. 完成标准

恢复工作完成前，不要以“新插件数量”或“App 能启动”作为标准。至少满足：

1. P0 能力在底层、UI、事件刷新和错误展示四层都有实现。
2. 每个旧版 Git 能力都能在能力账本中找到 `verified`、`partial` 或明确的产品弃用结论。
3. 所有标记为 `verified` 的写操作都有 fixture 回归测试。
4. 旧版的危险操作（discard、hard reset、revert、squash、abort）都有确认和失败恢复路径。
5. 当前 App 的工程生成、相关 package 测试和完整 Debug build 分别有真实命令输出作为证据。
6. 与旧版相比确实删除的能力，必须在账本和变更说明中明确列出，不能用重构后的相似 UI 代替说明。
