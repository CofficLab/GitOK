# Diff File Previews Implementation Plan

> Status: Phase 1, Phase 2, and the core Phase 3 preview routes are implemented in the working tree. Package builds and focused regression tests pass; the full application build remains the final verification step.

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 GitOK 的 DiffView 从“仅支持文本 unified diff”升级为按文件类型展示内容的文件变更查看器。

**Architecture:** 保留现有文本 Diff 链路不变，在 Git 数据层增加原始 blob / 工作区文件读取能力，在 Git Diff 插件内建立内容类型路由。PDF 使用 PDFKit 内嵌预览；图片、音频、视频使用原生 macOS 视图；Office 和其他不支持的二进制文件显示文件信息并提供外部打开入口。版本上下文始终由 commit、工作区和父 commit 决定，避免历史文件预览误读当前工作区。

**Tech Stack:** Swift 6, SwiftUI, macOS 14+, PDFKit, AVKit, QuickLook/NSWorkspace, Swift Package Manager, XCTest/Testing。

---

## 产品约束与验收标准

- 文本文件仍然使用 MagicDiffView，现有 diff、复制和视图切换行为不变。
- 新增 PDF 不再出现空白区域，能显示页数、文件大小并渲染页面。
- 修改 PDF 至少支持“旧版本 / 新版本”切换；删除 PDF 能查看删除前版本。
- 图片、音频、视频在支持的情况下内嵌展示；Office 和未知二进制文件显示明确状态、大小、类型和“打开文件”入口。
- 二进制读取全程使用 `Data`，禁止通过 UTF-8 字符串中转。
- 大文件、损坏文件和无法解析的格式必须有可理解的错误状态，不阻塞主界面。
- 所有加载支持取消、过期请求丢弃和加载进度/失败状态。
- 关键路由、Git blob 读取、文件类型识别和降级行为有自动化测试；最终通过插件测试和 GitOK 全量构建。

## Phase 1: 新增 PDF 内嵌预览

### Task 1: 增加原始 Git blob 读取 API

**Files:**
- Modify: `Packages/KitGit/Sources/KitGit/GitProcessRunner.swift`
- Modify: `Packages/KitGit/Sources/KitGit/GitDiffLoader.swift`
- Modify: `Packages/ProviderGit/Sources/ProviderGit/GitProviding.swift`
- Modify: `Packages/ProviderGit/Sources/ProviderGit/DefaultGitProvider.swift`
- Test: `Packages/KitGit/Tests/KitGitTests/GitDiffLoaderTests.swift`

实现 `runData` 和 `loadBlobData(commit:filePath:in:cancellation:)`。commit 模式使用 `git show <commit>:<path>` 读取原始字节；工作区模式读取当前文件。读取失败、路径不存在、取消和超时必须沿用现有 Git 错误语义。

### Task 2: 建立文件类型与展示内容模型

**Files:**
- Create: `Packages/PluginGitDiff/Sources/PluginGitDiff/Models/GitDiffContent.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/ViewModels/GitDiffViewModel.swift`
- Test: `Packages/PluginGitDiff/Tests/PluginGitDiffTests/GitDiffContentTests.swift`

定义 `DiffContentKind` 和 `DiffContent`，至少覆盖 `.text`, `.pdf`, `.image`, `.audio`, `.video`, `.unsupportedBinary`。识别优先使用文件签名和 UTI，扩展名只作为辅助；`.pdf` 同时校验 `%PDF-` 文件签名。加入大小上限和可展示原因，避免把任意二进制误判为 PDF。

### Task 3: 在 DiffView 中加入 PDF 预览

**Files:**
- Create: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/PDFDiffPreview.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/GitDiffPaneView.swift`
- Modify: `Packages/PluginGitDiff/Resources/Localizable.xcstrings`

将当前 `diffText` 状态扩展为内容加载状态。新增文件且识别为 PDF 时使用 `PDFKit.PDFDocument(data:)` 和 `PDFView` 内嵌渲染。顶部保留当前路径，并增加“新增 PDF / 页数 / 大小”信息；提供缩放和打开外部预览入口。加载中、损坏 PDF、超限 PDF 都要有明确状态。

### Task 4: 验证 Phase 1

运行：

```bash
swift test --package-path Packages/KitGit
swift test --package-path Packages/PluginGitDiff
```

验收：新增 PDF 显示第一页和页数；普通文本 diff 与之前一致；无效 PDF 显示错误而不是空白；取消选中文件后不会回写旧 PDF。

## Phase 2: 修改与删除 PDF 的版本查看

### Task 5: 扩展版本上下文数据

**Files:**
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/ViewModels/GitDiffViewModel.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/GitDiffPaneView.swift`
- Modify: `Packages/KitGit/Sources/KitGit/GitDiffLoader.swift`
- Modify: `Packages/ProviderGit/Sources/ProviderGit/GitProviding.swift`

为选中文件解析父 commit，并支持读取 old/new 两份 blob。新增文件只有 new；删除文件只有 old；修改文件同时有 old/new。读取键必须包含 commit、父 commit、路径和工作区上下文，防止缓存串版本。

### Task 6: 实现 PDF 版本切换和页面级差异提示

**Files:**
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/PDFDiffPreview.swift`
- Create: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/PDFVersionComparisonView.swift`
- Modify: `Packages/PluginGitDiff/Resources/Localizable.xcstrings`

修改 PDF 默认展示新版本，顶部提供“旧版本 / 新版本”切换；删除 PDF 默认展示旧版本并标记“已删除”。在两个版本都可解析时，按页数显示变化摘要，暂不承诺内容级文字 diff。版本不一致时明确显示“页数变化”，避免伪造精确差异。

### Task 7: 验证 Phase 2

为新增、修改、删除 PDF 添加 fixture 测试和 ViewModel 路由测试。手动确认父 commit 不存在的根提交、重命名文件和当前工作区文件不会崩溃或展示错误版本。

## Phase 3: 统一二进制文件预览体系

### Task 8: 增加可扩展的二进制预览路由

**Files:**
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Models/GitDiffContent.swift`
- Create: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/BinaryDiffPreview.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/GitDiffPaneView.swift`

图片使用 `Image` / `NSImage`，音频使用 `AVKit` 播放控件，视频使用 `VideoPlayer`。Office 和不支持格式显示统一的二进制信息卡，包含 UTI、文件大小、变更状态、复制路径、Finder 和默认应用打开入口。将所有类型的工具栏、错误和外部打开行为统一收敛到路由层。

### Task 9: 性能、安全与降级

**Files:**
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/GitDiffPaneView.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/PDFDiffPreview.swift`
- Modify: `Packages/PluginGitDiff/Sources/PluginGitDiff/Views/BinaryDiffPreview.swift`

对 Data 大小、PDF 页数和视频预览耗时设置保护；所有后台读取带取消句柄；不支持的 UTI 不尝试强制解码；外部打开前校验文件 URL 和当前项目路径。为键盘焦点、按钮无障碍标签、深色模式和失败状态补齐 UI 行为。

### Task 10: 完整验证

运行插件、KitGit 测试以及 GitOK Debug 构建。手动覆盖：文本文件、新增 PDF、修改 PDF、删除 PDF、PNG/JPEG、音频、视频、Office、未知二进制、大文件、损坏文件和快速切换多个文件。完成后更新插件 README，说明 DiffView 支持的文件类型和降级行为。
