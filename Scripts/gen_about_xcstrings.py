#!/usr/bin/env python3
"""Generate Localizable.xcstrings for all AboutView keys (en + zh variants).

zh-Hans translations are authored below; zh-Hant / zh-HK / zh-TW are derived
with OpenCC (s2t / s2hk / s2tw). Existing entries in the catalogs are kept.
"""
import glob
import json
import os
import re
import sys

try:
    from opencc import OpenCC
except ImportError:  # pragma: no cover
    OpenCC = None

T2 = OpenCC("s2t") if OpenCC else None
TW = OpenCC("s2tw") if OpenCC else None
HK = OpenCC("s2hk") if OpenCC else None

# key -> zh-Hans  (authoritative translation)
ZH: dict[str, str] = {
    # ---------- 通用 ----------
    "Core Capabilities": "核心能力",
    "How It Works": "工作原理",
    "Apply": "应用",
    "Persist": "持久保存",
    "Register": "注册",
    "Render": "渲染",
    "Merge": "合并",
    "Analyze": "分析",
    "Inspect": "检查",
    "Compose": "组装",
    "Update": "更新",
    "Status": "状态",
    "Export": "导出",
    "Clean": "干净",
    "Safe": "安全",
    "Add": "添加",
    "Preview": "预览",
    "Choose": "选择",
    "Templates": "模板",
    "Searchable": "可搜索",
    "Extensible": "可扩展",
    "Instant": "即时",
    "Instant Apply": "即时生效",
    "Branded": "品牌化",
    "Theme Aware": "主题感知",
    "Conventional": "Conventional",
    "glance": "一瞥",
    "click": "单击",
    "shortcut": "快捷键",
    "click to add": "一键添加",
    "click to export": "一键导出",
    "click to switch": "一键切换",
    "click to open": "一键打开",
    "click to commit": "一键提交",
    "click to merge": "一键合并",
    "click to clean": "一键清理",
    "click to resolve": "一键解决",
    "click to stash": "一键暂存",
    "Open settings": "打开设置",
    "Search & Filter": "搜索与筛选",
    "Sidebar": "侧边栏",
    "Untracked": "未跟踪",

    # ---------- PluginActivityStatus ----------
    "GitOK's heartbeat, visible at a glance.": "GitOK 的心跳，一目了然。",
    "Activity Feed": "活动流",
    "Repository events stream through a live indicator.": "仓库事件通过实时指示器持续流动。",
    "State Machine": "状态机",
    "Idle, running, and busy states reflect what GitOK is doing.": "空闲、运行与忙碌状态反映 GitOK 当前在做什么。",
    "Tile Integration": "磁贴集成",
    "The status renders as a compact tile in the workspace.": "状态以紧凑磁贴形式渲染在工作区中。",
    "Events arrive": "事件到达",
    "Git operations and file events report activity.": "Git 操作与文件事件上报活动。",
    "Update state": "更新状态",
    "The activity model transitions between states.": "活动模型在各状态间切换。",
    "Render tile": "渲染磁贴",
    "The tile redraws with the current heartbeat.": "磁贴随当前心跳重新绘制。",
    "Running": "运行中",
    "Idle": "空闲",
    "Busy": "忙碌",
    "state": "状态",
    "tile": "磁贴",

    # ---------- PluginBanner ----------
    "Beautiful banner art, generated and exported in one step.": "精美横幅，一步生成并导出。",
    "Banner Generation": "横幅生成",
    "Compose branded banners from GitOK's visual language.": "用 GitOK 的视觉语言创作品牌化横幅。",
    "One-Click Export": "一键导出",
    "Renders the banner to a file for social or marketing use.": "将横幅渲染为文件，用于社交媒体或营销。",
    "Colors follow the active theme automatically.": "颜色自动跟随当前主题。",
    "Configure": "配置",
    "Choose text, style, and theme for the banner.": "为横幅选择文字、样式与主题。",
    "The banner is drawn with the configured visuals.": "横幅按配置的视觉效果绘制。",
    "The image is written to the destination you choose.": "图片写入你选择的目标位置。",
    "Assets": "素材",
    "resolution": "分辨率",

    # ---------- PluginCommand ----------
    "Every action, reachable from the keyboard.": "所有操作，键盘即可触达。",
    "Command Palette": "命令面板",
    "Press the shortcut to open every command in one fuzzy list.": "按下快捷键，所有命令汇聚在一个模糊搜索列表里。",
    "Plugin Extensible": "插件可扩展",
    "Any plugin can register its own commands into the palette.": "任何插件都能把自己的命令注册进面板。",
    "Fuzzy Matching": "模糊匹配",
    "Type a few letters and the best command rises to the top.": "输入几个字母，最匹配的命令置顶。",
    "Press ⌘K": "按下 ⌘K",
    "The palette opens over the workspace.": "面板在工作区上方打开。",
    "Type & match": "输入并匹配",
    "Commands are fuzzy-matched against your input.": "命令与你的输入做模糊匹配。",
    "Run": "运行",
    "Selecting a command triggers its plugin action.": "选中命令即触发对应插件的动作。",
    "Fuzzy": "模糊",
    "⌘K": "⌘K",
    "commands": "命令数",

    # ---------- PluginCommitDetail ----------
    "Every commit, explained down to the last line.": "每个提交，解释到最后一行的细节。",
    "Complete Diff": "完整差异",
    "See every file change with precise additions and deletions.": "查看每个文件的精确增删变化。",
    "Rich Metadata": "丰富元信息",
    "Author, committer, timestamps, and full message at a glance.": "作者、提交者、时间戳与完整消息一览无余。",
    "File Navigator": "文件导航",
    "Jump between changed files in the commit instantly.": "在提交涉及的文件之间即时跳转。",
    "Pick a commit": "选择提交",
    "Select any row in the commit list.": "在提交列表中任选一行。",
    "Load the diff": "加载差异",
    "The commit's parents are diffed to build the change set.": "与父提交做差异，构建变更集。",
    "Browse files, hunks, and metadata in the detail pane.": "在详情面板中浏览文件、代码块与元信息。",
    "Diff": "差异",
    "Metadata": "元信息",
    "Files": "文件",
    "click from list": "从列表点击",
    "diff": "差异",

    # ---------- PluginCommitForm ----------
    "Write great commits without leaving the keyboard.": "不离开键盘，写出漂亮的提交。",
    "Message Editor": "消息编辑器",
    "Subject, body, and trailers with live length guidance.": "主题、正文与尾注，带实时长度提示。",
    "Conventional Style": "Conventional 风格",
    "Type, scope, and summary templates follow Conventional Commits.": "类型、作用域与摘要模板遵循 Conventional Commits。",
    "What You See": "所见即所得",
    "The exact staged content is shown before you commit.": "提交前清晰展示将要提交的暂存内容。",
    "Stage": "暂存",
    "Pick the changes to include in this commit.": "选择要包含进本次提交的改动。",
    "Write the message": "撰写消息",
    "Craft a subject, body, and any trailers.": "撰写主题、正文与任意尾注。",
    "Commit": "提交",
    "GitOK runs the commit and refreshes the tree.": "GitOK 执行提交并刷新工作树。",
    "Auto summary": "自动摘要",
    "coverage": "覆盖率",

    # ---------- PluginCommitList ----------
    "The full story of your repository, in one list.": "仓库的完整故事，尽在一个列表。",
    "Full History": "完整历史",
    "Browse the complete commit log across the current branch.": "浏览当前分支的完整提交日志。",
    "Live Refresh": "实时刷新",
    "New commits appear the moment the repository changes.": "仓库一有变化，新提交立刻出现。",
    "Search & Filter": "搜索与筛选",
    "Filter by message, author, or time range in an instant.": "按消息、作者或时间范围即时筛选。",
    "Walk the log": "遍历日志",
    "Git walks commits from HEAD back through history.": "Git 从 HEAD 出发回溯历史提交。",
    "Decorate": "装饰",
    "Branches, tags, and authors enrich each row.": "分支、标签与作者丰富了每一行。",
    "Select & inspect": "选择并查看",
    "Clicking a commit opens its detail view.": "点击提交打开其详情视图。",
    "All branches": "全部分支",
    "Live": "实时",
    "Searchable": "可搜索",
    "commits": "提交数",
    "updates": "更新",

    # ---------- PluginCommitStatusBar ----------
    "Your commit health, always visible at the bottom.": "提交健康度，始终显示在底部。",
    "Clean Indicator": "干净指示器",
    "A green mark when the working tree matches HEAD.": "工作树与 HEAD 一致时显示绿色标记。",
    "Dirty Indicator": "脏状态指示器",
    "Uncommitted changes light up the status bar instantly.": "未提交改动立刻点亮状态栏。",
    "Ahead / Behind": "领先 / 落后",
    "Unpushed and unpulled counts sit next to the branch.": "未推送与未拉取计数紧随分支显示。",
    "Read the tree": "读取工作树",
    "The status service compares tree and index.": "状态服务对比工作树与索引。",
    "Update the bar": "更新状态栏",
    "Indicators redraw with the current state.": "指示器随当前状态重绘。",
    "Stay current": "保持同步",
    "File events keep the indicator in sync.": "文件事件让指示器保持同步。",
    "Dirty": "脏",
    "Ahead": "领先",
    "Behind": "落后",
    "Ahead/Behind": "领先/落后",
    "status": "状态",

    # ---------- PluginCommitToast ----------
    "Every commit confirmed the moment it lands.": "每次提交落地即获确认。",
    "Instant Feedback": "即时反馈",
    "A short confirmation appears right after each commit.": "每次提交后立即出现简短确认。",
    "Quick Undo": "快速撤销",
    "Roll back the last commit directly from the toast.": "直接从 toast 撤销上一次提交。",
    "Stay Out of the Way": "不打扰",
    "Toasts auto-dismiss and never block your workflow.": "toast 自动消失，绝不阻塞工作流。",
    "Commit succeeds": "提交成功",
    "The commit service reports success.": "提交服务报告成功。",
    "Show toast": "显示 toast",
    "A confirmation toast renders at the top of the window.": "确认 toast 渲染在窗口顶部。",
    "Act or ignore": "操作或忽略",
    "Undo from the toast, or let it fade away.": "从 toast 撤销，或任其淡出。",
    "Actionable": "可操作",
    "Non-blocking": "不阻塞",
    "toast per commit": "每次提交一条 toast",
    "interruptions": "打扰次数",

    # ---------- PluginDiagnosticsSettings ----------
    "When something feels off, start here.": "感觉不对劲时，从这里开始。",
    "Log Viewer": "日志查看器",
    "Browse GitOK's runtime logs with filters.": "带筛选浏览 GitOK 运行时日志。",
    "Diagnostics Inspector": "诊断检查器",
    "Inspect providers, plugins, and services state.": "检查提供方、插件与服务的状态。",
    "Repro Guidance": "复现指引",
    "Export details that make issues reproducible.": "导出让问题可复现的细节。",
    "Open diagnostics": "打开诊断",
    "The diagnostics view loads current state.": "诊断视图加载当前状态。",
    "Logs and services are explored with filters.": "带筛选探索日志与服务。",
    "Report": "报告",
    "Relevant details are exported for support.": "导出相关细节用于支持排查。",
    "Logs": "日志",
    "Inspector": "检查器",
    "Repro": "复现",
    "place to diagnose": "诊断入口",
    "visibility": "可见性",

    # ---------- PluginFileInfo ----------
    "Every file's story, at your fingertips.": "每个文件的故事，尽在指尖。",
    "File History": "文件历史",
    "Every commit that touched the selected file, newest first.": "涉及所选文件的每次提交，最新在前。",
    "Blame": "追溯",
    "See who changed each line and when.": "查看每一行是谁、在何时修改的。",
    "Rich Status": "丰富状态",
    "Tracked, staged, modified, or untracked — always clear.": "已跟踪、已暂存、已修改或未跟踪——始终清晰。",
    "Select a file": "选择文件",
    "Pick any file in the worktree view.": "在工作树视图中任选文件。",
    "Query git": "查询 git",
    "Log, status, and blame are gathered for the path.": "为该路径收集日志、状态与追溯信息。",
    "Present": "呈现",
    "History and blame render beside the file.": "历史与追溯信息渲染在文件旁边。",
    "Changes": "变更",
    "selection": "选择",
    "history": "历史",

    # ---------- PluginGitAutoPush ----------
    "Your commits travel to the remote on their own.": "你的提交自动前往远程。",
    "Push on Commit": "提交即推送",
    "New commits are pushed to the tracked remote automatically.": "新提交自动推送到所跟踪的远程。",
    "Per-Project Control": "按项目控制",
    "Enable or disable auto-push for each repository.": "可逐仓库启用或关闭自动推送。",
    "Failure Awareness": "失败感知",
    "Failed pushes are surfaced instead of silently retried.": "推送失败会明确呈现，而非静默重试。",
    "Commit lands": "提交落地",
    "A new local commit is created.": "创建了一条新的本地提交。",
    "Push triggers": "触发推送",
    "Auto-push runs against the configured remote.": "自动推送按配置的远程执行。",
    "Verify": "验证",
    "The remote ref is confirmed and status updates.": "确认远程引用并更新状态。",
    "Automatic": "自动",
    "Configurable": "可配置",
    "manual pushes": "手动推送",
    "sync": "同步",

    # ---------- PluginGitBranchStatus ----------
    "Where you are, and where you stand — always visible.": "你在哪、站在什么位置——始终可见。",
    "Current Branch": "当前分支",
    "The active branch name is always in view.": "当前分支名始终在视野中。",
    "Unpushed Count": "未推送数",
    "How many local commits wait on the remote.": "有多少本地提交等待推送到远程。",
    "Unpulled Count": "未拉取数",
    "How many remote commits you have not pulled yet.": "还有多少远程提交尚未拉取。",
    "Read HEAD": "读取 HEAD",
    "The current branch and ref are resolved.": "解析当前分支与引用。",
    "Compare remotes": "对比远程",
    "Local and remote refs are compared.": "对比本地与远程引用。",
    "Render status": "渲染状态",
    "Branch and counts appear in the status bar.": "分支与计数显示在状态栏。",
    "Branch": "分支",
    "position": "位置",

    # ---------- PluginGitCommitStyleSettings ----------
    "Your repository's commit style, enforced consistently.": "仓库的提交风格，保持一致。",
    "Style Presets": "风格预设",
    "Choose Conventional Commits or a custom style.": "选择 Conventional Commits 或自定义风格。",
    "Message Templates": "消息模板",
    "Define subject and body templates for the commit form.": "为提交表单定义主题与正文模板。",
    "Live Guidance": "实时引导",
    "The form nudges messages toward the chosen style.": "表单引导消息贴合所选风格。",
    "Pick a style": "选择风格",
    "Set the convention for the repository.": "为仓库设定提交规范。",
    "Shape the form": "塑造表单",
    "Templates guide subject, body, and trailers.": "模板引导主题、正文与尾注。",
    "Commit cleanly": "整洁提交",
    "Messages follow the style without friction.": "消息无摩擦地遵循风格。",
    "Guides": "引导",
    "style per repo": "每仓库一种风格",
    "guidance": "引导",

    # ---------- PluginGitConflictResolver ----------
    "Conflicts resolved with clarity, not guesswork.": "解决冲突靠清晰，而非猜测。",
    "Keep Ours": "保留我方",
    "Take the current branch's version of the conflict.": "采用当前分支对冲突的版本。",
    "Keep Theirs": "保留对方",
    "Take the incoming branch's version.": "采用传入分支的版本。",
    "Merge Manually": "手动合并",
    "Open the conflicted file and craft the final content.": "打开冲突文件，手工整理最终内容。",
    "Detect": "检测",
    "Conflicted files are detected across the repository.": "检测整个仓库中的冲突文件。",
    "Pick ours, theirs, or edit by hand.": "选择我方、对方或手工编辑。",
    "Stage the result": "暂存结果",
    "The resolution is staged and marked resolved.": "解决方案被暂存并标记为已解决。",
    "Ours": "我方",
    "Theirs": "对方",
    "Both": "双方",
    "resolution choices": "解决选项",

    # ---------- PluginGitDiff ----------
    "Diff made legible — hunk by hunk, line by line.": "差异清晰可读——逐块、逐行。",
    "Side-by-Side": "并排对比",
    "Compare old and new content in parallel columns.": "新旧内容并行分列对比。",
    "Word Highlight": "词级高亮",
    "Intra-line changes are highlighted, not just whole lines.": "行内变化也被高亮，而不仅仅是整行。",
    "Hunk Navigation": "代码块导航",
    "Jump between every changed hunk with one key.": "一键在每一个变更块之间跳转。",
    "Request the diff": "请求差异",
    "Any view asks for a diff between two refs or files.": "任何视图都可在两个引用或文件间请求差异。",
    "Parse hunks": "解析代码块",
    "Git's diff output is split into structured hunks.": "git 的差异输出被拆分为结构化代码块。",
    "Hunks render inline or side-by-side with highlights.": "代码块以行内或并排方式渲染并高亮。",
    "Inline": "行内",
    "Side-by-side": "并排",
    "Word-level": "词级",
    "view modes": "视图模式",
    "granularity": "精细度",

    # ---------- PluginGitIgnore ----------
    "Keep noise out of your repository, effortlessly.": "轻松把噪音挡在仓库之外。",
    "Template Library": "模板库",
    "Start from curated templates for common languages and tools.": "从精选的常用语言与工具模板起步。",
    "Live Preview": "实时预览",
    "See which files would be ignored as you edit the rules.": "编辑规则时实时预览哪些文件将被忽略。",
    "Nested Rules": "嵌套规则",
    "Repo-level and global ignore rules are respected together.": "仓库级与全局忽略规则共同生效。",
    "Edit rules": "编辑规则",
    "Add patterns to .gitignore.": "向 .gitignore 添加模式。",
    "Evaluate": "评估",
    "Git re-reads the rules against the working tree.": "git 重新对照工作树读取规则。",
    "Stay clean": "保持整洁",
    "Matching files disappear from untracked status.": "匹配的文件从未跟踪状态中消失。",
    "Live preview": "实时预览",
    "Per-path": "按路径",
    "file to rule them": "一份规则文件",
    "templates": "模板数",

    # ---------- PluginGitLFS ----------
    "Large files, stored smart, cloned fast.": "大文件，聪明存放，快速克隆。",
    "LFS Backing": "LFS 存储",
    "Large binary content is stored outside the repository.": "大型二进制内容存放在仓库之外。",
    "Track Patterns": "跟踪模式",
    "Declare which file types are managed by LFS.": "声明哪些文件类型由 LFS 管理。",
    "Fast Clones": "快速克隆",
    "Repositories stay light — content is pulled on demand.": "仓库保持轻量——内容按需拉取。",
    "Track": "跟踪",
    "File patterns are marked for LFS.": "文件模式被标记为 LFS 管理。",
    "Commit pointers": "提交指针",
    "Git stores a small pointer instead of the payload.": "git 存储小指针而非实际内容。",
    "Fetch content": "获取内容",
    "LFS downloads the real file when you check it out.": "检出时 LFS 下载真实文件。",
    "LFS": "LFS",
    "Pointer-based": "指针式",
    "command": "命令",
    "file size": "文件大小",

    # ---------- PluginGitNetworkSettings ----------
    "Talk to remotes the way your network expects.": "按你的网络期望与远程通信。",
    "Proxy Support": "代理支持",
    "Route Git traffic through HTTP or SOCKS proxies.": "让 Git 流量经由 HTTP 或 SOCKS 代理。",
    "SSL Verification": "SSL 校验",
    "Tune certificate verification for corporate environments.": "为企业环境调整证书校验。",
    "Timeout Control": "超时控制",
    "Set connection and operation timeouts to match your network.": "设置连接与操作超时，贴合你的网络。",
    "Adjust settings": "调整设置",
    "Configure proxy, SSL, and timeout values.": "配置代理、SSL 与超时值。",
    "Settings are written to the Git config.": "设置写入 Git 配置。",
    "Apply to remotes": "应用到远程",
    "All network operations honor the new values.": "所有网络操作遵循新值。",
    "Proxy": "代理",
    "SSL": "SSL",
    "Timeouts": "超时",
    "tuning areas": "调优区域",
    "global config": "全局配置",

    # ---------- PluginGitRemoteRepository ----------
    "Remotes managed with full control.": "远程仓库，尽在掌控。",
    "Add Remote": "添加远程",
    "Attach new remotes with any name and URL.": "以任意名称与地址添加新远程。",
    "Edit & Rename": "编辑与重命名",
    "Update URLs or rename remotes without losing tracking.": "更新地址或重命名远程而不丢失跟踪。",
    "Remove Safely": "安全移除",
    "Detach remotes with clear confirmation.": "带明确确认解除远程关联。",
    "List remotes": "列出远程",
    "Current remotes are read from the repo config.": "从仓库配置读取当前远程列表。",
    "Modify": "修改",
    "Add, rename, or remove entries.": "添加、重命名或移除条目。",
    "Save config": "保存配置",
    "Changes are persisted to the repository.": "变更持久化到仓库。",
    "Remove": "移除",
    "Rename": "重命名",
    "remotes": "远程数",

    # ---------- PluginGitRepositorySettings ----------
    "Fine-tune how GitOK treats each repository.": "精细调整 GitOK 对待每个仓库的方式。",
    "Per-Repo Options": "仓库级选项",
    "Customize behavior for the currently open repository.": "为当前打开的仓库定制行为。",
    "Local Git Config": "本地 Git 配置",
    "Edits apply to the repository's local config file.": "修改作用于仓库的本地配置文件。",
    "Changes take effect without restarting GitOK.": "改动无需重启 GitOK 即生效。",
    "Changes apply immediately, no restarts required.": "改动立即生效，无需重启。",
    "Open settings": "打开设置",
    "Repository settings are scoped to the active project.": "仓库设置作用于当前项目。",
    "Edit values": "编辑值",
    "Tune repository-specific options.": "调整仓库专属选项。",
    "Values are written to the local Git config.": "值写入本地 Git 配置。",
    "Local config": "本地配置",
    "Per-project": "按项目",
    "Persistent": "持久生效",
    "config scope": "配置作用域",
    "repo at a time": "一次一个仓库",

    # ---------- PluginGitSmartMerge ----------
    "Merges that understand your branches.": "懂你分支的合并。",
    "Branch Aware": "分支感知",
    "Understands where your branches diverged and why.": "理解分支从哪里、为何分叉。",
    "Conflict Detection": "冲突检测",
    "Potential conflicts are flagged before you commit to the merge.": "提交合并前即标记潜在冲突。",
    "Reversible": "可回退",
    "Merges can be abandoned cleanly if something feels wrong.": "感觉不对时可以干净地放弃合并。",
    "The divergence between branches is computed.": "计算分支间的分叉情况。",
    "Git performs the merge with your chosen strategy.": "git 按你选择的策略执行合并。",
    "Resolve & verify": "解决并验证",
    "Conflicts are listed for resolution; the tree is verified.": "列出冲突待解决，并验证工作树。",
    "Conflict-aware": "冲突感知",
    "conflict risk": "冲突风险",

    # ---------- PluginGitStash ----------
    "Park your work in progress, pick it up later.": "把进行中的工作暂存起来，稍后再取。",
    "Stash Changes": "暂存改动",
    "Set aside tracked and untracked work with one click.": "一键搁置已跟踪与未跟踪的工作。",
    "Stash List": "暂存列表",
    "Every stash is listed with its message and age.": "每条暂存都带消息与时间列出。",
    "Apply & Drop": "应用与丢弃",
    "Re-apply a stash to your tree, and drop it when done.": "把暂存应用回工作树，用完即弃。",
    "Stash": "暂存",
    "Working changes are saved and the tree is restored.": "工作改动被保存，工作树恢复原状。",
    "Work elsewhere": "切换到别处",
    "Switch branches or tasks freely.": "自由切换分支或任务。",
    "Restore": "恢复",
    "Apply the stash back and resolve any conflicts.": "把暂存应用回来并解决冲突。",
    "List": "列表",
    "stashes": "暂存数",

    # ---------- PluginGitSubmodule ----------
    "Nested repositories, managed with care.": "嵌套仓库，精心管理。",
    "Add Submodule": "添加子模块",
    "Nest an external repository at any path.": "在任意路径嵌套外部仓库。",
    "Sync & Update": "同步与更新",
    "Pull registered submodules to the recorded commit.": "把已注册子模块拉取到记录的提交。",
    "Status Overview": "状态总览",
    "See which submodules are out of date or dirty.": "查看哪些子模块过期或变脏。",
    "Register": "注册",
    "A submodule is added to the index and .gitmodules.": "子模块被加入索引与 .gitmodules。",
    "Initialize": "初始化",
    "The nested repository is fetched on demand.": "嵌套仓库按需获取。",
    "Track & update": "跟踪与更新",
    "Commits pin the submodule; updates move it forward.": "提交固定子模块，更新推动其前进。",
    "submodule control": "子模块控制",

    # ---------- PluginGitUnpushedStatus ----------
    "Never lose track of what hasn't reached the remote.": "永远不丢失未到达远程的内容。",
    "Unpushed Detection": "未推送检测",
    "Commits that never reached the remote are counted.": "统计从未到达远程的提交。",
    "Gentle Reminders": "温和提醒",
    "A subtle indicator keeps the state visible.": "一个细微指示器让状态保持可见。",
    "Per-Branch Clarity": "分支级清晰",
    "Each branch shows its own ahead/behind position.": "每个分支显示自己的领先/落后位置。",
    "Compare refs": "对比引用",
    "Local branches are compared with their remotes.": "本地分支与其远程对比。",
    "Count commits": "统计提交",
    "The ahead count is computed per branch.": "逐分支计算领先数。",
    "Show reminder": "显示提醒",
    "The status bar surfaces the unpushed count.": "状态栏呈现未推送计数。",
    "Unpushed": "未推送",
    "Reminder": "提醒",
    "Per branch": "按分支",
    "tracking": "跟踪",
    "unpushed commits": "未推送提交",

    # ---------- PluginGitUserSettings ----------
    "Your Git identity, set once, used everywhere.": "你的 Git 身份，一次设置，处处使用。",
    "Author Identity": "作者身份",
    "Configure the name and email used on every commit.": "配置每次提交使用的姓名与邮箱。",
    "Commit Signing": "提交签名",
    "Optionally sign commits with your GPG or SSH key.": "可选地使用 GPG 或 SSH 密钥为提交签名。",
    "Repo Overrides": "仓库覆盖",
    "Per-repository identities override the global default.": "仓库级身份可覆盖全局默认。",
    "Edit settings": "编辑设置",
    "Update name, email, or signing key.": "更新姓名、邮箱或签名密钥。",
    "Write config": "写入配置",
    "Git config is updated safely.": "Git 配置被安全更新。",
    "Commit with identity": "以身份提交",
    "New commits carry the configured author.": "新提交携带配置的作者。",
    "Name": "姓名",
    "Email": "邮箱",
    "Signing": "签名",
    "fields": "字段数",
    "identity": "身份",

    # ---------- PluginIcon ----------
    "App icons, sized for every platform automatically.": "应用图标，自动适配各平台尺寸。",
    "Icon Generation": "图标生成",
    "Compose app icons from GitOK's visual language.": "用 GitOK 的视觉语言创作应用图标。",
    "Multi-Size Export": "多尺寸导出",
    "Every required icon size is rendered in one pass.": "一次渲染所有必需的图标尺寸。",
    "Colors and styles follow the active theme.": "颜色与样式跟随当前主题。",
    "Design": "设计",
    "Pick the icon style and colors.": "选择图标样式与颜色。",
    "Render sizes": "渲染尺寸",
    "All required resolutions are rendered.": "渲染所有必需的尺寸。",
    "Icons are written to the destination folder.": "图标写入目标文件夹。",
    "All sizes": "全尺寸",
    "source icon": "源图标",
    "output sizes": "输出尺寸",

    # ---------- PluginLicense ----------
    "Licensing made transparent, for GitOK and your projects.": "许可透明，覆盖 GitOK 与你的项目。",
    "Project License": "项目许可",
    "Read GitOK's license and open-source notices in-app.": "在应用内阅读 GitOK 的许可与开源声明。",
    "Third-Party Credit": "第三方致谢",
    "Every dependency is credited with its license terms.": "每个依赖都附带其许可条款致谢。",
    "Transparency": "透明度",
    "Compliance information is one click away.": "合规信息一键可达。",
    "Open licenses": "打开许可",
    "Browse the license view from settings.": "从设置进入许可视图。",
    "Read terms": "阅读条款",
    "Each component's license text is available.": "每个组件的许可文本均可查阅。",
    "Stay informed": "保持知情",
    "Updates keep attribution current.": "更新让致谢保持最新。",
    "Open Source": "开源",
    "Attribution": "致谢",
    "In-app": "应用内",
    "attribution": "致谢",
    "place to read": "阅读入口",

    # ---------- PluginLogoCoffic ----------
    "The Coffic mark that fronts GitOK.": "站在 GitOK 门面的 Coffic 标志。",
    "Brand Mark": "品牌标志",
    "Contributes the official Coffic logo to GitOK.": "为 GitOK 贡献官方 Coffic Logo。",
    "Highlight Ready": "支持高亮",
    "Supports the highlighted state for special moments.": "支持特殊时刻的高亮状态。",
    "Manager Friendly": "管理器友好",
    "Registers through the central logo manager.": "通过集中式 Logo 管理器注册。",
    "The Coffic logo item is registered.": "Coffic Logo 条目已注册。",
    "The logo manager merges and orders it.": "Logo 管理器合并并排序它。",
    "GitOK draws the Coffic mark.": "GitOK 绘制 Coffic 标志。",
    "Brand": "品牌",
    "Coffic": "Coffic",
    "Always on": "常驻",
    "logo": "Logo",
    "owner": "归属",

    # ---------- PluginProjects ----------
    "Your repositories, always one click away.": "你的仓库，始终一键可达。",
    "Recents": "最近打开",
    "Recently opened projects surface at the top, newest first.": "最近打开的项目置顶，最新在前。",
    "Pinned Projects": "置顶项目",
    "Pin frequently used repositories so they never leave your sight.": "置顶常用仓库，让它们永不出视野。",
    "Type to filter the whole list by name, path, or platform.": "按名称、路径或平台过滤整个列表。",
    "Record opens": "记录打开",
    "Every project you open is remembered in order.": "每次打开的项目按顺序被记住。",
    "Build the list": "构建列表",
    "Recents, pins, and search results merge into one list.": "最近、置顶与搜索结果合并为一个列表。",
    "Open in place": "原地打开",
    "Clicking a project switches the whole workspace to it.": "点击项目将整个工作区切换到它。",
    "Recent": "最近",
    "Pinned": "置顶",
    "Quick Open": "快速打开",
    "projects": "项目数",

    # ---------- PluginRootView ----------
    "The window that hosts the entire GitOK workspace.": "承载整个 GitOK 工作区的窗口。",
    "Project list, repository tree, and navigation live on the left.": "项目列表、仓库树与导航位于左侧。",
    "Content Area": "内容区",
    "Commits, diffs, worktrees, and settings render in the main pane.": "提交、差异、工作树与设置渲染在主面板。",
    "Status Bar": "状态栏",
    "Branch, worktree, and activity indicators sit at the bottom.": "分支、工作树与活动指示器位于底部。",
    "Register regions": "注册区域",
    "Each feature registers its toolbar, sidebar, or content views.": "每个功能注册自己的工具栏、侧边栏或内容视图。",
    "Compose the window": "组装窗口",
    "The root view assembles all registered regions into one layout.": "根视图把所有注册区域组装为一个布局。",
    "Switch projects": "切换项目",
    "Opening a project re-renders the workspace around it.": "打开项目即围绕它重新渲染工作区。",
    "Content": "内容",
    "core regions": "核心区域",
    "window": "窗口",

    # ---------- PluginSettingGeneral ----------
    "The app-wide preferences that tie everything together.": "把所有功能串起来的应用级偏好。",
    "General Options": "通用选项",
    "Launch behavior, window, and interface preferences.": "启动行为、窗口与界面偏好。",
    "App Information": "应用信息",
    "Version, build, and environment details at a glance.": "版本、构建与环境信息一览无余。",
    "Open General": "打开通用",
    "The general section opens in settings.": "通用分区在设置中打开。",
    "Adjust": "调整",
    "Toggle app-wide behaviors.": "切换应用级行为。",
    "Preferences persist and take effect at once.": "偏好持久保存并立即生效。",
    "General": "通用",
    "App Info": "应用信息",
    "Behavior": "行为",
    "general page": "通用页面",
    "options": "选项",

    # ---------- PluginSettingView ----------
    "A home for every plugin's preferences.": "每个插件偏好的家园。",
    "Section Sidebar": "分区侧边栏",
    "All settings are organized in a navigable sidebar.": "所有设置组织在可导航的侧边栏中。",
    "Plugin Sections": "插件分区",
    "Each plugin contributes its own settings page.": "每个插件贡献自己的设置页面。",
    "Jump to any setting by typing.": "输入即可跳转到任意设置。",
    "Plugins register setting sections with titles.": "插件注册带标题的设置分区。",
    "The settings window assembles the sidebar.": "设置窗口组装侧边栏。",
    "Navigate": "导航",
    "Selecting a section shows its content.": "选中分区显示其内容。",
    "Sections": "分区",
    "sections": "分区数",
    "settings window": "设置窗口",

    # ---------- PluginSettingsButton ----------
    "Every setting, one gear away.": "所有设置，一个齿轮之遥。",
    "Toolbar Entry": "工具栏入口",
    "A gear button sits in the toolbar of the workspace.": "齿轮按钮驻留在工作区工具栏。",
    "Settings Hub": "设置中心",
    "Opens the settings window with all plugin sections.": "打开包含所有插件分区的设置窗口。",
    "Discoverability": "可发现性",
    "Every preference is reachable without hunting.": "每个偏好都无需翻找即可到达。",
    "Click the gear": "点击齿轮",
    "The toolbar button activates.": "工具栏按钮被激活。",
    "The settings window appears.": "设置窗口出现。",
    "Browse sections": "浏览分区",
    "All plugin settings are organized on the left.": "所有插件设置组织在左侧。",
    "Toolbar": "工具栏",
    "Settings": "设置",
    "Always there": "始终在线",
    "gear": "齿轮",

    # ---------- PluginSidebarToggle ----------
    "More room for code, whenever you need it.": "需要时，给代码更多空间。",
    "Show / Hide": "显示 / 隐藏",
    "Collapse or expand the sidebar in one action.": "一个动作折叠或展开侧边栏。",
    "Keyboard Friendly": "键盘友好",
    "A shortcut keeps your hands on the keys.": "快捷键让你的手不离键盘。",
    "Workspace Focus": "工作区聚焦",
    "Free up horizontal space for content and diffs.": "为内容与差异腾出横向空间。",
    "Trigger": "触发",
    "Click the toolbar button or press the shortcut.": "点击工具栏按钮或按下快捷键。",
    "Animate": "动画",
    "The sidebar collapses or expands smoothly.": "侧边栏平滑折叠或展开。",
    "Your preference is remembered for next time.": "你的偏好会被记住，下次沿用。",
    "Toggle": "开关",
    "Shortcut": "快捷键",

    # ---------- PluginStatusBar ----------
    "The quiet strip that keeps you oriented.": "让你保持方向的安静状态条。",
    "Central Strip": "中央状态条",
    "A shared status bar at the bottom of the workspace.": "工作区底部共享的状态栏。",
    "Indicator Host": "指示器宿主",
    "Plugins register indicators that appear in order.": "插件注册按顺序出现的指示器。",
    "Order Control": "顺序控制",
    "Each indicator's position is deterministic.": "每个指示器的位置是确定的。",
    "Plugins add their indicators with an order.": "插件带顺序添加自己的指示器。",
    "The bar lays out all indicators.": "状态条布局所有指示器。",
    "Indicators redraw as state changes.": "指示器随状态变化重绘。",
    "Hosts": "宿主",
    "indicators": "指示器",
    "strip": "状态条",

    # ---------- PluginThemePack ----------
    "A look that feels like yours.": "一种像你的外观。",
    "Theme Library": "主题库",
    "Switch between built-in light and dark themes.": "在内置浅色与深色主题间切换。",
    "Accent Colors": "强调色",
    "Personalize the accent used across the UI.": "个性化界面各处使用的强调色。",
    "System Sync": "系统同步",
    "Follow the system appearance automatically.": "自动跟随系统外观。",
    "Pick a theme": "选择主题",
    "Choose from the theme library.": "从主题库中选择。",
    "The theme is broadcast to the whole app.": "主题广播到整个应用。",
    "Your choice is remembered across launches.": "你的选择在多次启动间被记住。",
    "Themes": "主题",
    "Accent": "强调色",
    "Light/Dark": "浅色/深色",
    "themes": "主题数",

    # ---------- PluginWorktreeClean ----------
    "Sweep away clutter and keep your repository pristine.": "扫走杂乱，让仓库保持纯净。",
    "Dry Run First": "先试运行",
    "Preview every file that would be removed before anything happens.": "在动手前预览每个将被移除的文件。",
    "Untracked Cleanup": "未跟踪清理",
    "Remove stray untracked files and directories safely.": "安全移除游离的未跟踪文件与目录。",
    "Protected by Default": "默认受保护",
    "Tracked content is never touched, only verified clutter goes.": "已跟踪内容绝不触碰，只清除确认的杂乱。",
    "Git reports what is untracked or ignored.": "git 报告未跟踪或被忽略的内容。",
    "You review the exact list in a dry run.": "你在试运行中审阅确切清单。",
    "Confirm, and the clutter is removed.": "确认后，杂乱被移除。",
    "Dry Run": "试运行",
    "Ignored": "已忽略",
    "risk with dry run": "试运行风险",

    # ---------- PluginWorktreeStatus ----------
    "See exactly what changed in your working tree.": "精确看到工作树发生了什么变化。",
    "Modified Files": "已修改文件",
    "Tracked files with uncommitted changes appear instantly.": "带未提交改动的已跟踪文件立即出现。",
    "Untracked Files": "未跟踪文件",
    "New files show up until you decide to track or ignore them.": "新文件持续显示，直到你决定跟踪或忽略。",
    "Staged Changes": "已暂存改动",
    "The index state is shown separately from working-tree edits.": "索引状态与工作树编辑分开显示。",
    "Scan the tree": "扫描工作树",
    "Git compares working tree and index against HEAD.": "git 将工作树与索引对比 HEAD。",
    "Categorize": "分类",
    "Files are grouped by modified, staged, or untracked.": "文件按已修改、已暂存或未跟踪分组。",
    "Refresh live": "实时刷新",
    "File events re-scan the tree and update the list.": "文件事件重新扫描工作树并更新列表。",
    "Changed": "已修改",
    "Staged": "已暂存",
    "change kinds": "变更种类",
    "refresh": "刷新",
}


def variants(zh_hans: str) -> dict[str, str]:
    out = {"zh-Hans": zh_hans}
    if T2 and TW and HK:
        out["zh-Hant"] = T2.convert(zh_hans)
        out["zh-HK"] = HK.convert(zh_hans)
        out["zh-TW"] = TW.convert(zh_hans)
    else:
        out["zh-Hant"] = out["zh-HK"] = out["zh-TW"] = zh_hans
    return out


def extract(path: str) -> list[str]:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    keys = []
    for m in re.finditer(r'L\("((?:[^"\\]|\\.)*)"', text):
        key = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
        if key not in keys:
            keys.append(key)
    return keys


def merge(pkg_dir: str, entries: dict[str, dict[str, str]]) -> None:
    resources = os.path.join(pkg_dir, "Resources")
    os.makedirs(resources, exist_ok=True)
    path = os.path.join(resources, "Localizable.xcstrings")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            catalog = json.load(f)
    else:
        catalog = {"sourceLanguage": "en", "strings": {}, "version": "1.0"}
    strings = catalog.setdefault("strings", {})
    for key, langs in entries.items():
        entry = strings.get(key) or {"localizations": {}}
        strings[key] = entry
        loc = entry.setdefault("localizations", {})
        en = langs.get("en") or key
        for lang in ("en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"):
            loc[lang] = {"stringUnit": {"state": "translated", "value": langs.get(lang) or en}}
    catalog["sourceLanguage"] = "en"
    catalog["strings"] = dict(sorted(strings.items(), key=lambda kv: kv[0]))
    catalog["version"] = "1.0"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> None:
    missing: set[str] = set()
    for f in sorted(glob.glob("Packages/*/Sources/*/Views/*AboutView.swift")):
        pkg_name = f.split("/")[1]
        pkg_dir = "Packages/" + pkg_name
        keys = extract(f)
        entries = {}
        for k in keys:
            if k not in ZH:
                missing.add(k)
                continue
            entries[k] = {"en": k, **variants(ZH[k])}
        if entries:
            merge(pkg_dir, entries)
            print(f"merged {len(entries):2d} keys -> {pkg_dir}")
    if missing:
        print("\nMISSING TRANSLATIONS:")
        for k in sorted(missing):
            print("  ", k)
        sys.exit(1)


if __name__ == "__main__":
    main()
