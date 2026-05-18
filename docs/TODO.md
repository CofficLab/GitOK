# TODO

## 当前待修复问题

## 修复历史 Commit 文件列表误显示“未暂存”

- 现象：在历史 commit 详情的 FileList 中，已提交文件仍显示“未暂存”标签。
- 预期：历史 commit 文件列表不应展示工作区/暂存区状态；应隐藏暂存状态标签，或改为展示 commit diff 的变更类型，例如新增、修改、删除、重命名。
- 初步原因：`FileList` 在查看 commit 时不会读取当前 status entries，`stageState(for:)` 在未命中 staged/unstaged path 时默认返回 `.unstaged`，导致历史 commit 文件被错误标记为“未暂存”。
- 相关位置：
  - `APP/Plugins/Git-Detail/Git-File/FileList.swift`
  - `APP/Plugins/Git-Detail/Git-File/FileTile.swift`
- 验收标准：
  - 查看历史 commit 时，文件行不再显示“未暂存”。
  - 查看当前工作区改动时，已暂存、未暂存、部分暂存状态仍正常显示。

## GitHub Desktop 参考能力清单

参考路径：`/Users/colorfy/Code/CofficLab/desktop/`

对比对象是 GitHub Desktop 风格的 Electron 项目能力面。GitOK 已有自己的产品方向（项目管理、图标、Banner、插件系统），下面只整理 Git 工作流和桌面体验上可借鉴、缺失或需要完善的部分。

## 当前 GitOK 已覆盖的能力

- [x] 项目列表与项目选择：`APP/Plugins/ProjectPicker`、`APP/Core/Views/Projects`
- [x] 打开外部工具：Finder、Terminal、VS Code、Cursor、Xcode、Trae 等插件
- [x] Clone 任意远程仓库：`APP/Plugins/Git-Clone`
- [x] Git 状态、文件列表、Diff、提交列表、Commit 表单：`APP/Plugins/Git-Detail`
- [x] Commit message 风格/分类、用户信息、Co-author 基础能力
- [x] Branch 查看、创建、切换、Merge：`APP/Plugins/Git-Branch`、`APP/Plugins/Git-Merge`
- [x] Push、Pull、Sync、Auto Pull、Auto Push：`APP/Plugins/Git-Push`、`APP/Plugins/Git-Pull`、`APP/Plugins/Git-Sync`、`APP/Plugins/AutoPush`
- [x] 远程仓库列表、新增、编辑、删除：`APP/Plugins/Git-RemoteRepository`
- [x] Stash 保存、列表、Apply、Pop、Drop：`APP/Plugins/Git-Stash`
- [x] Merge conflict 状态、stage、continue、abort：`APP/Plugins/Git-ConflictResolver`
- [x] Gitignore、README、LICENSE 编辑/查看：`APP/Plugins/Git-Ignore`、`APP/Plugins/Readme`、`APP/Plugins/License`
- [x] App Icon 与 Banner 生成，这是 GitOK 相比 Desktop 的差异化能力

## P0：核心 Git 工作流缺口

- [x] 新建本地仓库 / 初始化仓库
  - Desktop 参考：`app/src/ui/add-repository/create-repository.tsx`、`app/src/lib/git/init.ts`
  - GitOK 现状：左侧添加入口已支持“新建仓库”，可选择目录、校验仓库名、执行 `git init`、创建 README、`.gitignore`、MIT LICENSE、初始提交，并自动导入项目列表。
  - 后续：更多 LICENSE/.gitignore 模板、创建后 Publish 到远端、初始提交用户配置引导仍可继续完善。

- [ ] GitHub/GitHub Enterprise 账号登录与仓库列表 Clone
  - Desktop 参考：`app/src/ui/sign-in`、`app/src/lib/auth.ts`、`app/src/ui/clone-repository/clone-github-repository.tsx`
  - GitOK 现状：Clone 更偏通用 URL 输入。
  - TODO：账号登录、token/credential 安全存储、列出用户/组织仓库、搜索仓库、选择账号 Clone。

- [ ] Publish repository / Publish branch
  - Desktop 参考：`app/src/ui/publish-repository`、`app/src/models/publish-settings.ts`
  - GitOK 现状：可以管理 remote 和 push，但没有一键创建远端仓库并设置 upstream。
  - TODO：创建远程仓库、选择公开/私有、设置 `origin`、首次 push、已有 remote 冲突处理。

- [x] Fetch 与 ahead/behind 状态体系
  - Desktop 参考：`app/src/lib/git/fetch.ts`、`app/src/lib/stores/ahead-behind-store.ts`
  - GitOK 现状：已增加 fetch、ahead/behind 查询、Push 按钮远端差异状态、non-fast-forward 专门提示，并修正 Sync 为 fetch-first。
  - 后续：后台定时 fetch、离线/认证失败状态、状态栏统一展示仍可继续打磨。

- [ ] 精细化 stage / unstage / partial commit
  - Desktop 参考：`app/src/ui/changes`、`app/src/lib/git/stage.ts`
  - GitOK 现状：已支持文件级 stage/unstage、文件暂存状态展示；提交按钮在存在 staged 改动时只提交 staged，否则保留一键提交全部。
  - TODO：按 hunk/行选择、过滤后提交确认、Changes / Staged Changes 分区展示。

- [x] 安全的 discard / restore 体验
  - Desktop 参考：`app/src/ui/discard-changes`
  - GitOK 现状：单文件和全部 discard 已改为 Git CLI restore/rm/clean 路径；确认弹窗会区分已暂存、未暂存、未跟踪文件，并提示新文件会被删除；底层覆盖 tracked staged+unstaged、staged new file、untracked file 的恢复/删除。
  - 后续：失败重试、被覆盖文件提示、可配置“不再确认”仍可继续完善。

- [ ] Branch 完整管理
  - Desktop 参考：`app/src/ui/branches`、`app/src/ui/rename-branch`、`app/src/ui/delete-branch`
  - GitOK 现状：已有查看、创建、切换、合并。
  - TODO：重命名分支、删除本地分支、删除远程分支、发布分支、设置/修改 upstream、分支搜索和分组。

- [ ] History Compare / 分支比较
  - Desktop 参考：`app/src/ui/history/compare.tsx`、`app/src/lib/compare.ts`
  - GitOK 现状：已有提交列表和提交文件 diff，但缺少分支/范围比较。
  - TODO：选择 base/head、展示 ahead/behind commits、变更文件汇总、从比较结果发起 merge/rebase。

## P1：高级 Git 操作

- [ ] Rebase 工作流
  - Desktop 参考：`app/src/ui/rebase`、`app/src/lib/git/rebase.ts`
  - TODO：rebase preview、开始 rebase、冲突处理、continue/abort、成功/失败 banner。

- [ ] Cherry-pick / multi-commit operation
  - Desktop 参考：`app/src/lib/git/cherry-pick.ts`、`app/src/ui/multi-commit-operation`
  - TODO：选择一个或多个 commit、跨分支 cherry-pick、冲突后的继续/中止。

- [ ] Squash、Revert、Reset
  - Desktop 参考：`app/src/lib/git/squash.ts`、`app/src/lib/git/revert.ts`、`app/src/ui/reset`
  - GitOK 现状：已有未推送 HEAD commit 的 undo/reset mixed。
  - TODO：多提交 squash、revert pushed commit、soft/mixed/hard reset 的安全 UI。

- [ ] Tag 创建/删除/推送
  - Desktop 参考：`app/src/ui/create-tag`、`app/src/ui/delete-tag`、`app/src/lib/git/tag.ts`
  - GitOK 现状：commit row 能显示 tag。
  - TODO：创建 lightweight/annotated tag、删除本地 tag、推送 tag、删除远端 tag。

- [ ] Git LFS 支持
  - Desktop 参考：`app/src/ui/lfs`、`app/src/lib/git/lfs.ts`
  - TODO：检测 LFS、初始化 LFS、attribute mismatch 提示、大文件建议。

- [ ] Submodule 支持
  - Desktop 参考：`app/src/lib/git/submodule.ts`、`app/src/ui/diff/submodule-diff.tsx`
  - TODO：显示 submodule diff、初始化/更新 submodule、错误提示。

## P1：PR、Issue 与托管平台集成

- [ ] Pull Request 列表、创建、预览、打开
  - Desktop 参考：`app/src/ui/open-pull-request`、`app/src/models/pull-request.ts`
  - TODO：当前分支关联 PR、创建 PR、PR 状态、打开网页、复制链接。

- [ ] PR Review / Comment / Notification
  - Desktop 参考：`app/src/ui/notifications`、`app/src/models/popup.ts` 中 Pull Request Review/Comment 相关 popup
  - TODO：PR review 通知、评论入口、未读状态。

- [ ] Issues 与 mention/autocomplete
  - Desktop 参考：`app/src/lib/databases/issues-database.ts`、`app/src/ui/autocompletion`
  - TODO：commit/PR 文本中的 issue mention、用户 mention、emoji autocomplete。

- [ ] CI checks 展示与 rerun
  - Desktop 参考：`app/src/ui/check-runs`、`app/src/lib/ci-checks`
  - TODO：commit/PR 的 check 状态、失败详情、跳转 Actions、rerun 权限判断。

- [ ] 多平台远程服务文档和适配
  - Desktop 参考：`docs/integrations/gitlab.md`、`docs/integrations/bitbucket.md`、`docs/integrations/azure-devops.md`
  - TODO：GitHub、GitLab、Bitbucket、Azure DevOps remote URL 识别、打开远程页面、认证差异说明。

## P1：Diff 与文件体验完善

- [ ] Side-by-side diff、inline diff 切换
  - Desktop 参考：`app/src/ui/diff/side-by-side-diff.tsx`
  - TODO：统一 diff mode 设置、横向滚动、长行处理、文件级选项。

- [ ] 语法高亮与 diff 搜索
  - Desktop 参考：`app/src/ui/diff/syntax-highlighting`、`app/src/ui/diff/diff-search-input.tsx`
  - TODO：按文件类型高亮、搜索命中跳转、大小写/正则选项。

- [ ] 图片 diff
  - Desktop 参考：`app/src/ui/diff/image-diffs`
  - TODO：two-up、swipe、onion skin、difference blend，适配 GitOK 的 Icon/Banner 场景。

- [ ] 二进制文件、超大 diff、空白字符提示
  - Desktop 参考：`app/src/ui/diff/binary-file.tsx`、`diff-contents-warning.tsx`、`whitespace-hint-popover.tsx`
  - TODO：大文件跳过策略、二进制文件说明、忽略空白切换。

## P1：认证、网络与系统集成

- [ ] 通用 Git 认证弹窗
  - Desktop 参考：`app/src/ui/generic-git-auth`、`app/src/lib/generic-git-auth.ts`
  - TODO：用户名/密码/token 提示、失败重试、credential helper 集成。

- [ ] SSH passphrase / SSH 用户密码
  - Desktop 参考：`app/src/lib/ssh`
  - GitOK 现状：已有 `SSHHelper` 做 URL 转换，但交互式认证还不完整。
  - TODO：SSH key passphrase 弹窗、known_hosts/host key 错误说明、凭据缓存。

- [ ] Proxy、证书与企业网络
  - Desktop 参考：`docs/technical/proxies.md`、`app/src/ui/untrusted-certificate`
  - TODO：HTTP/HTTPS proxy 设置、PAC、证书错误提示、企业证书信任流程。

- [ ] External editor / shell 设置
  - Desktop 参考：`app/src/ui/preferences`、`app/src/lib/editors`、`app/src/lib/shells`
  - GitOK 现状：已有多个打开工具插件。
  - TODO：自动检测已安装编辑器/终端、默认工具设置、不可用时降级和提示。

## P2：桌面产品完整度

- [ ] App menu 与快捷键体系
  - Desktop 参考：`app/src/ui/app-menu`、`app/src/ui/keyboard-shortcut`
  - TODO：常用 Git 操作快捷键、菜单状态禁用、Command Palette 可选。

- [ ] Welcome / Tutorial / No repositories 引导
  - Desktop 参考：`app/src/ui/welcome`、`app/src/ui/tutorial`、`app/src/ui/no-repositories`
  - TODO：首次启动引导、添加/Clone/Create 三入口、示例项目提示。

- [ ] 错误、日志、崩溃窗口
  - Desktop 参考：`app/src/crash`、`app/src/ui/app-error.tsx`、`app/src/lib/logging`
  - TODO：统一错误分类、可复制诊断信息、日志路径入口、崩溃恢复。

- [ ] Release notes / 更新流程
  - Desktop 参考：`app/src/ui/release-notes`、`app/src/ui/installing-update`
  - GitOK 现状：已有 appcast 和 updater view。
  - TODO：版本更新说明、后台检查、下载进度、失败重试。

- [ ] Accessibility 与键盘导航
  - Desktop 参考：`app/src/ui/accessibility`、`app/src/ui/lib/list`
  - TODO：VoiceOver 标签、焦点管理、列表键盘选择、多选操作。

## 已有功能需要优先打磨

- [x] `Git-Sync` 的操作顺序需要重新评估
  - 现状：`Project.sync()` 已调整为先 fetch，再根据 ahead/behind 决定 pull/push；本地和远端同时有新提交时提示用户处理。
  - 已验证：`swift test --enable-code-coverage`、`xcodebuild -scheme GitOK -destination 'platform=macOS' build`。

- [ ] `Git-Stash` 需要补充上下文
  - 现状：只显示 index 和 message。
  - 建议：显示创建分支、创建时间、文件数量、stash diff 预览，并在 apply/pop 前检测工作区是否 clean。

- [ ] `Git-ConflictResolver` 需要从“状态面板”升级为“解决工作流”
  - 现状：提示用户去编辑器解决，再回 GitOK stage/continue。
  - 建议：提供 ours/theirs/base 文件入口、冲突文件 diff、打开外部编辑器、继续/中止的状态解释。

- [ ] `Git-Clone` 需要进度、认证和错误分层
  - 现状：调用 `git clone`，失败时显示命令错误。
  - 建议：显示 clone 进度、支持认证弹窗、目标目录冲突修复、网络/权限/仓库不存在分层提示。

- [ ] `Git-Detail` 的工作区模型需要更清晰
  - 现状：staged/unstaged 合并展示较多，适合轻量使用。
  - 建议：拆出 Changes / Staged Changes / History 三个稳定区域，支持过滤、搜索、多选和 partial commit。

- [ ] Remote 管理需要与 Push/Pull 状态联动
  - 现状：remote CRUD 与 push/pull 入口相对独立。
  - 建议：新增 remote 后提示首次 push，remote URL 改动后刷新 ahead/behind，删除 remote 前解释影响。

## 推荐实施顺序

1. 打牢本地 Git 闭环：Create Repository、stage/unstage、discard 安全确认。
2. 补全分支和历史：branch rename/delete/upstream、history compare、tag 管理。
3. 完善高风险操作：rebase、cherry-pick、squash/revert/reset、conflict resolver。
4. 接入远程平台：GitHub auth、publish repo/branch、PR 创建/展示、CI checks。
5. 做桌面体验：快捷键、引导、错误日志、更新说明、无障碍。

## 已完成专项归档

### Push Behind Remote 工作流

目标：参考 GitHub Desktop 的处理方式，让 GitOK 在“本地分支落后远程，同时本地又有新提交”时给出明确、可恢复的工作流。

设计原则：

- 不在 push 失败后自动 pull、merge 或 rebase。
- 状态已知时，用按钮状态提前引导用户先 Pull/Fetch。
- 状态未知时，允许 push 失败，但将 non-fast-forward 映射为专门提示。
- Fetch 是安全操作，可以作为 push 失败后的默认下一步。

完成项：

- [x] 增加底层 Git fetch 能力：`GitRepositoryCLI.fetch(remote:)`、`Project.fetch()`、`projectDidFetch` 事件。
- [x] 增加 ahead/behind 查询能力：新增 `GitAheadBehind`，使用 `git rev-list --left-right --count HEAD...@{upstream}` 查询当前分支与 upstream 的差异。
- [x] 在 `ProjectVM` 暴露远端差异状态：`aheadCount`、`behindCount`、`hasUpstream`、`lastFetchedAt`。
- [x] 改造 Push 按钮状态：落后远端时引导 Pull，领先时显示 Push，无 upstream 时显示 Publish Branch/设置 upstream 入口。
- [x] 捕获 push non-fast-forward，并映射为 `pushNeedsFetch`。
- [x] 增加 PushNeedsPull/Fetch 提示，主按钮为 `Fetch`，第一版不自动 Pull/Rebase。
- [x] 修正 Sync 顺序：先 Fetch，再根据 ahead/behind 决定 Pull 或 Push；本地和远端同时有新提交时提示用户选择 Pull/Rebase。

当前进度：8/8，已通过 `swift test` 和 `xcodebuild -scheme GitOK -destination 'platform=macOS' build`。
