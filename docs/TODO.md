# TODO

## GitHub Desktop 参考能力清单

参考路径：`/Users/colorfy/Code/CofficLab/desktop/`

对比对象是 GitHub Desktop 风格的 Electron 项目能力面。GitOK 已有自己的产品方向（项目管理、图标、Banner、插件系统），下面只整理 Git 工作流和桌面体验上可借鉴、缺失或需要完善的部分。

## P0：核心 Git 工作流缺口

- [x] GitHub/GitHub Enterprise 账号登录与仓库列表 Clone
  - Desktop 参考：`app/src/ui/sign-in`、`app/src/lib/auth.ts`、`app/src/ui/clone-repository/clone-github-repository.tsx`
  - GitOK 现状：Clone 面板保留通用 URL 输入，同时新增 GitHub / Enterprise 账号 Clone 区域；用户可输入 GitHub host、用户名和 PAT，GitOK 通过 GitHub/GHE API 列出可访问仓库，支持搜索并选择仓库自动填入 clone URL 和仓库名；token 会写入当前 Git credential helper，后续 HTTPS clone 可复用系统凭据。
  - TODO：后续可补完整 OAuth/device-flow 登录、账号多配置、组织分页和头像/权限缓存。

- [x] Publish repository / Publish branch
  - Desktop 参考：`app/src/ui/publish-repository`、`app/src/models/publish-settings.ts`
  - GitOK 现状：分支表单已支持发布当前分支；Remote 管理面板在当前分支缺少 upstream 时提供“发布当前分支”，会使用选中 remote（优先 `origin`）执行首次 `git push -u` 并设置 upstream；已有 remote 冲突通过新增/编辑/删除 remote 流程处理。
  - TODO：后续接入平台 API 后，可补一键创建远程仓库、公开/私有选择、GitHub/GitLab 等平台认证与远端仓库创建。

- [x] 精细化 stage / unstage / partial commit
  - Desktop 参考：`app/src/ui/changes`、`app/src/lib/git/stage.ts`
  - GitOK 现状：已支持 Changes / Staged Changes 分区、文件级与批量 stage/unstage、文件暂存状态展示；提交按钮在存在 staged 改动时只提交 staged，否则保留一键提交全部。
  - TODO：后续可继续补过滤后提交前的最终确认摘要。

## P1：高级 Git 操作

- [x] Squash、Revert、Reset
  - Desktop 参考：`app/src/lib/git/squash.ts`、`app/src/lib/git/revert.ts`、`app/src/ui/reset`
  - GitOK 现状：提交行右键菜单支持 Revert 指定提交并创建反向提交；支持 reset 到指定提交的 soft/mixed/hard 三种模式，并用确认弹窗说明暂存区/工作区影响；未推送提交范围支持从 HEAD 到所选提交 squash 为一个新提交；保留已有未推送 HEAD commit 的 undo/reset mixed 快捷入口。
  - TODO：后续可补交互式 rebase 列表、squash 前提交消息编辑预览，以及 reset 前自动 stash/备份提示。

## P1：PR、Issue 与托管平台集成

- [x] Pull Request 列表、创建、预览、打开
  - Desktop 参考：`app/src/ui/open-pull-request`、`app/src/models/pull-request.ts`
  - GitOK 现状：分支比较面板已提供 PR 预览基础数据（ahead/behind、head 独有提交、变更文件）；识别 GitHub、GitLab、Bitbucket、Azure DevOps remote 后，可打开创建 PR 页面、当前 head 分支相关 PR 页面、仓库 PR 列表，并复制创建 PR 链接。
  - TODO：后续接入账号/API 后，可补应用内 PR 列表、当前分支关联 PR 状态、review/check 摘要和草稿 PR 创建。

- [x] PR Review / Comment / Notification
  - Desktop 参考：`app/src/ui/notifications`、`app/src/models/popup.ts` 中 Pull Request Review/Comment 相关 popup
  - GitOK 现状：分支比较面板已在 PR 操作区提供 Review 请求、评论、通知入口；识别 GitHub、GitLab、Bitbucket、Azure DevOps remote 后，会打开对应平台的 review-request、评论/活动或通知筛选页面。当前未读状态依赖托管平台网页。
  - TODO：后续接入账号/API 后，可补应用内未读计数、review/comment 通知流、标记已读和原生评论编辑。

- [x] Issues 与 mention/autocomplete
  - Desktop 参考：`app/src/lib/databases/issues-database.ts`、`app/src/ui/autocompletion`
  - GitOK 现状：提交信息输入框已支持本地 autocomplete：从本地/远程分支名提取 `#123` issue 引用，从常用 co-author 提取 `@user` 候选，并内置常用 emoji shortcode；输入 `#`、`@`、`:` 后可点选插入。
  - TODO：后续接入账号/API 后，可补平台 issue 搜索、PR 文本编辑器内 autocomplete、用户头像/真实 handle、emoji 全量索引和离线缓存。

- [x] CI checks 展示与 rerun
  - Desktop 参考：`app/src/ui/check-runs`、`app/src/lib/ci-checks`
  - GitOK 现状：提交行已根据 remote 生成 CI 入口；识别 GitHub、GitLab、Bitbucket、Azure DevOps 后，可从提交行打开 commit checks/pipelines、Actions/Pipelines 运行列表和重新运行入口。当前状态、失败详情和 rerun 权限依赖托管平台网页。
  - TODO：后续接入账号/API 后，可补应用内 check 状态、失败日志摘要、PR check 汇总、rerun 权限判断和原生 rerun 操作。

- [x] 多平台远程服务文档和适配
  - Desktop 参考：`docs/integrations/gitlab.md`、`docs/integrations/bitbucket.md`、`docs/integrations/azure-devops.md`
  - GitOK 现状：已在 `ProjectRulesKit.RemoteRepositoryFormRules` 中识别 GitHub、GitLab、Bitbucket、Azure DevOps remote URL；Remote 管理、Repository 设置、Guide 和打开远程工具栏共用同一套浏览器链接转换；文档见 `docs/integrations/remote-hosting.md`。
  - TODO：后续如接入平台 API 登录，再补各平台的 OAuth/token 配置界面。

## P1：Diff 与文件体验完善

- [x] Side-by-side diff、inline diff 切换
  - Desktop 参考：`app/src/ui/diff/side-by-side-diff.tsx`
  - GitOK 现状：FileDetail 使用的 `MagicDiffView(diffOutput:)` 已内置差异/并排/原文本/新文本切换，支持行号、折叠、主题切换和文本复制；FileDetail 额外提供大 diff 保护等文件级选项。
  - TODO：后续可把默认 diff mode、长行策略和折叠阈值提升为用户设置。

- [x] 语法高亮
  - Desktop 参考：`app/src/ui/diff/syntax-highlighting`
  - GitOK 现状：`MagicDiffView` 已按内容检测语言并做语法高亮。
  - TODO：后续可把高亮策略提升为用户设置。

- [x] 图片 diff
  - Desktop 参考：`app/src/ui/diff/image-diffs`
  - GitOK 现状：FileDetail 对修改图片支持并排、滑动、叠加和差异混合四种对比模式；新增/删除图片继续使用单图预览，适配 Icon/Banner 等二进制图片变更查看。
  - TODO：后续可补图片尺寸、文件大小和缩放比例等元信息。

- [x] 二进制文件、超大 diff、空白字符提示
  - Desktop 参考：`app/src/ui/diff/binary-file.tsx`、`diff-contents-warning.tsx`、`whitespace-hint-popover.tsx`
  - GitOK 现状：FileDetail 已区分二进制文件和图片预览；超大文本 diff 会跳过渲染并提供复制原始 diff / 查看原文本 / 查看新文本。
  - TODO：后续可把超大 diff 阈值做成设置项。

## P1：认证、网络与系统集成

- [x] 通用 Git 认证弹窗
  - Desktop 参考：`app/src/ui/generic-git-auth`、`app/src/lib/generic-git-auth.ts`
  - GitOK 现状：Clone、工作区 push/pull 认证失败时会显示用户名和 token/密码输入；凭据通过 `git credential approve` 写入当前 Git credential helper，保存后会自动重试原操作；HTTPS remote 会从当前 remote URL 推断 credential host。
  - TODO：后续可把菜单触发的 fetch/pull/push 失败也接入同一弹窗，并补 OAuth/SSO 平台登录。

- [x] SSH passphrase / SSH 用户密码
  - Desktop 参考：`app/src/lib/ssh`
  - GitOK 现状：已有 `SSHHelper` 做 URL 转换；Clone、Push、Pull 遇到 SSH key/passphrase 或 host key 失败时会区分 SSH 认证失败和 SSH 主机验证失败，不再误导到 HTTPS token 表单；应用内提供 SSH 处理面板，可复制 `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`、按 remote host 生成 `ssh-keyscan` 命令、打开 `~/.ssh` 目录，并在处理后重试原操作。
  - TODO：后续可进一步接入原生 askpass/Keychain passphrase 写入，减少用户跳转终端的步骤。

- [x] Proxy、证书与企业网络
  - Desktop 参考：`docs/technical/proxies.md`、`app/src/ui/untrusted-certificate`
  - GitOK 现状：设置页新增“网络”入口，可读写 Git 全局 `http.proxy`、`https.proxy`、`http.sslVerify` 和 `http.sslCAInfo`；Clone 错误分类已单独识别代理认证/连接失败和 SSL/企业证书验证失败，并给出对应恢复建议；证书设置支持选择 CA 文件、打开钥匙串访问以完成企业证书信任流程。
  - TODO：后续可补 PAC 自动发现、按仓库覆盖网络配置，以及更细的代理认证凭据保存。

## P2：桌面产品完整度

- [x] App menu 与快捷键体系
  - Desktop 参考：`app/src/ui/app-menu`、`app/src/ui/keyboard-shortcut`
  - GitOK 现状：已新增 `Git` 菜单，支持刷新、Fetch、Pull、Push、仓库设置；菜单状态通过当前 focused `ProjectVM` 禁用不可用操作；快捷键覆盖 `Cmd+R`、`Shift+Cmd+F`、`Shift+Cmd+P`、`Cmd+P`、`Option+Cmd+,`。
  - TODO：Command Palette 可选。

- [x] 错误、日志、崩溃窗口
  - Desktop 参考：`app/src/crash`、`app/src/ui/app-error.tsx`、`app/src/lib/logging`
  - GitOK 现状：设置页新增“诊断”入口；应用启动/退出会记录 clean-exit 标记，下一次启动可提示上次可能未正常退出；`projectOperationDidFail` 和 `appError` 会汇总到最近错误列表；诊断页支持复制包含 App/macOS/Git 版本、应用支持目录、最近错误和 `log show` 命令的诊断报告，并提供打开 Console 和应用支持目录的入口。
  - TODO：后续可接入真正的 crash reporter、持久化跨会话错误队列，以及错误弹窗中的“一键附加诊断信息”。

- [x] Accessibility 与键盘导航
  - Desktop 参考：`app/src/ui/accessibility`、`app/src/ui/lib/list`
  - GitOK 现状：文件变更行已补 VoiceOver 汇总标签、状态/暂存信息和操作提示；项目行、标签按钮会暴露选中状态；文件列表支持上下键移动选择、Delete 触发丢弃确认；批量暂存/取消暂存/丢弃/全选提供快捷键和无障碍提示。
  - TODO：后续可继续覆盖更多插件自定义控件的细粒度 VoiceOver 文案。

## 已有功能需要优先打磨

- [x] `Git-Clone` 需要进度、认证和错误分层
  - GitOK 现状：Clone 面板已显示实时 Git 进度；目标目录会预检 existing project / 非空目录 / 同名文件；失败提示已按认证、仓库不可用、网络、目标路径、未知错误分层，并保留原始 Git 输出；HTTPS 认证失败时会弹出用户名/token 输入，使用当前 Git credential helper 保存后自动重试 clone。
  - TODO：后续可扩展 SSH passphrase、企业 SSO/OAuth 和平台仓库列表选择。

## 推荐实施顺序

1. 补全分支和历史：branch rename/upstream、history compare、tag 管理。
2. 完善高风险操作：rebase、cherry-pick、squash/revert/reset、conflict resolver。
3. 接入远程平台：GitHub auth、publish repo/branch、PR 创建/展示、CI checks。
4. 做桌面体验：快捷键、引导、错误日志、更新说明、无障碍。
