import AppKit
import LibGit2Swift
import MagicDiffView
import MagicAlert
import MagicKit

import OSLog
import SwiftUI

struct FileDetail: View, SuperLog, SuperEvent, SuperThread {
    
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var unifiedDiffText = ""
    @State private var diffIssueMessage: String?
    @State private var showTextPreview = false
    @State private var textPreviewTitle = ""
    @State private var textPreviewContent = ""

    static let emoji = "🌍"

    private var verbose = false

    var body: some View {
        VStack(spacing: 0) {
            if let file = vm.file {
                // 文件路径显示组件
                HStack(spacing: 6) {
                    Image(systemName: fileIcon)
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text(file.file)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.background)

                // 根据文件类型显示不同内容
                if file.isBinary {
                    binaryFileView
                } else {
                    diffContentView(for: file)
                }
            }
        }
        .onChange(of: vm.file, onFileChange)
        .onChange(of: data.commit, onCommitChange)
        .onAppear(perform: onAppear)
        .sheet(isPresented: $showTextPreview) {
            textPreviewSheet
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func diffContentView(for file: GitDiffFile) -> some View {
        if unifiedDiffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyDiffView(for: file)
        } else {
            MagicDiffView(diffOutput: unifiedDiffText)
                .background(.background)
        }
    }

    /// 文件图标
    private var fileIcon: String {
        if let file = vm.file {
            if file.isImage { return "photo" }
            if file.isBinary { return "doc.badge.gearshape" }
        }
        return "doc.text"
    }

    /// 二进制文件视图
    @ViewBuilder
    private var binaryFileView: some View {
        if let file = vm.file, file.isImage {
            imageView(for: file)
        } else {
            genericBinaryView
        }
    }

    /// 图片文件视图
    @ViewBuilder
    private func imageView(for file: GitDiffFile) -> some View {
        let changeType = file.changeType.uppercased()

        if changeType == "A" || changeType == "?" {
            // 新增的图片
            imagePreviewSection(title: "新增的图片", image: loadImageFromCommit(file: file))
        } else if changeType == "D" {
            // 删除的图片
            imagePreviewSection(title: "已删除的图片", image: loadImageBefore(file: file))
        } else {
            // 修改的图片：显示 before / after 对比
            HStack(spacing: 0) {
                // Before
                VStack(spacing: 0) {
                    Text("修改前")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))

                    imagePreview(image: loadImageBefore(file: file))
                }

                Divider()

                // After
                VStack(spacing: 0) {
                    Text("修改后")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))

                    imagePreview(image: loadImageFromCommit(file: file))
                }
            }
        }
    }

    /// 单图预览区域
    private func imagePreviewSection(title: String, image: NSImage?) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))

            imagePreview(image: image)
        }
    }

    /// 通用图片预览
    @ViewBuilder
    private func imagePreview(image: NSImage?) -> some View {
        if let image = image {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            maxWidth: max(image.size.width, geometry.size.width),
                            maxHeight: .infinity
                        )
                        .padding(8)
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("无法加载图片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 通用二进制文件视图（非图片）
    private var genericBinaryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("二进制文件")
                .font(.headline)
                .foregroundColor(.primary)

            Text("此文件无法以文本方式显示差异")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func emptyDiffView(for file: GitDiffFile) -> some View {
        VStack(spacing: 14) {
            Image(systemName: diffIssueMessage == nil ? "doc.text.magnifyingglass" : "exclamationmark.triangle")
                .font(.system(size: 34))
                .foregroundColor(diffIssueMessage == nil ? .secondary : .orange)

            Text(diffIssueMessage == nil ? "没有可显示的差异内容" : "无法显示差异")
                .font(.headline)
                .foregroundColor(.primary)

            Text(emptyDiffExplanation(for: file))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let diffIssueMessage, !diffIssueMessage.isEmpty {
                Text("原因：\(diffIssueMessage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Text("文件状态：\(changeTypeLabel(for: file))")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button("刷新") {
                    refreshDiff()
                }

                if hasBeforeText(for: file) {
                    Button("查看原文本") {
                        presentTextPreview(kind: .before, for: file)
                    }
                }

                if hasAfterText(for: file) {
                    Button("查看新文本") {
                        presentTextPreview(kind: .after, for: file)
                    }
                }

                if let diffIssueMessage, !diffIssueMessage.isEmpty {
                    Button("复制原因") {
                        copyToPasteboard(diffIssueMessage)
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    // MARK: - Image Loading

    /// 从当前 commit 加载图片
    private func loadImageFromCommit(file: GitDiffFile) -> NSImage? {
        guard let project = vm.project else { return nil }

        if let commit = data.commit {
            // 从指定 commit 中加载二进制数据
            do {
                let data = try project.fileData(at: commit.hash, file: file.file)
                return NSImage(data: data)
            } catch {
                return nil
            }
        } else {
            // 从工作区加载
            let fullPath = URL(fileURLWithPath: project.path)
                .appendingPathComponent(file.file).path
            return NSImage(contentsOfFile: fullPath)
        }
    }

    /// 加载修改前的图片
    private func loadImageBefore(file: GitDiffFile) -> NSImage? {
        guard let project = vm.project else { return nil }

        if let commit = data.commit {
            // 获取父 commit 中的文件
            let commits = try? LibGit2.getCommitList(at: project.path)
            guard let currentCommit = commits?.first(where: { $0.hash == commit.hash }),
                  let parentHash = currentCommit.parentHashes.first else {
                return nil
            }
            do {
                let data = try project.fileData(at: parentHash, file: file.file)
                return NSImage(data: data)
            } catch {
                return nil
            }
        } else {
            // 未提交的变更，从 HEAD 加载
            guard let headHash = project.headCommitHash() else { return nil }
            do {
                let data = try project.fileData(at: headHash, file: file.file)
                return NSImage(data: data)
            } catch {
                return nil
            }
        }
    }

    private func emptyDiffExplanation(for file: GitDiffFile) -> String {
        if let message = diffIssueMessage, !message.isEmpty {
            return "Diff 数据没有成功生成。你可以先检查文件是否仍然存在、编码是否为文本，或者刷新当前视图。"
        }

        switch file.changeType.uppercased() {
        case "A", "?":
            return "这个新增文件目前没有生成可解析的文本 diff。常见原因是文件为空、内容不是标准文本，或底层 Git 没返回 patch。你仍然可以直接查看新文本。"
        case "D":
            return "这个删除文件当前没有拿到可显示的 patch。常见原因是文件内容为空，或底层 Git 没返回删除差异。你仍然可以查看删除前的文本。"
        default:
            return "当前文件没有可显示的文本差异。可能是内容未变化、文件为空，或 diff 输出为空。你可以直接查看原文本和新文本确认。"
        }
    }

    private func changeTypeLabel(for file: GitDiffFile) -> String {
        switch file.changeType.uppercased() {
        case "A": return "已暂存新增"
        case "?": return "未跟踪新增"
        case "M": return "已修改"
        case "D": return "已删除"
        case "R": return "已重命名"
        case "C": return "已复制"
        case "T": return "类型变更"
        default: return file.changeType
        }
    }

    private var textPreviewSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text(textPreviewTitle)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            ScrollView([.horizontal, .vertical]) {
                Text(textPreviewContent)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(.background)
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private enum TextVersion {
        case before
        case after
    }

    private func refreshDiff() {
        self.bg.async {
            updateDiffView(reason: "Manual Refresh")
        }
    }

    private func hasBeforeText(for file: GitDiffFile) -> Bool {
        switch file.changeType.uppercased() {
        case "A", "?":
            return false
        default:
            return true
        }
    }

    private func hasAfterText(for file: GitDiffFile) -> Bool {
        switch file.changeType.uppercased() {
        case "D":
            return false
        default:
            return true
        }
    }

    private func presentTextPreview(kind: TextVersion, for file: GitDiffFile) {
        self.bg.async {
            do {
                let content = try loadTextContent(kind: kind, for: file)
                let title = kind == .before ? "原文本" : "新文本"

                DispatchQueue.main.async {
                    self.textPreviewTitle = "\(title) · \(file.file)"
                    self.textPreviewContent = content
                    self.showTextPreview = true
                }
            } catch {
                let message = "无法加载\(kind == .before ? "原文本" : "新文本"): \(error.localizedDescription)"
                os_log(.error, "\(Self.t)❌ \(message)")
                DispatchQueue.main.async {
                    self.diffIssueMessage = message
                    alert_error(message)
                }
            }
        }
    }

    private func loadTextContent(kind: TextVersion, for file: GitDiffFile) throws -> String {
        guard let project = vm.project else {
            throw GitDetailError.invalidProject
        }

        let contents: (before: String?, after: String?)
        if let commit = data.commit {
            contents = try project.fileContentChange(at: commit.hash, file: file.file)
        } else {
            contents = try project.uncommittedFileContentChange(file: file.file)
        }

        switch kind {
        case .before:
            guard let before = contents.before else {
                throw GitDetailError.fileNotFound("原文本不存在")
            }
            return before.isEmpty ? "/* 空文件 */" : before
        case .after:
            guard let after = contents.after else {
                throw GitDetailError.fileNotFound("新文本不存在")
            }
            return after.isEmpty ? "/* 空文件 */" : after
        }
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func updateDiffView(reason: String) {
        if verbose {
            os_log("\(self.t)🍋 UpdateDiffView(\(reason))")
        }

        guard let file = vm.file, let project = vm.project else {
            return
        }

        // 二进制文件不需要获取 diff 文本
        if file.isBinary {
            self.unifiedDiffText = ""
            self.diffIssueMessage = nil
            return
        }

        do {
            if let commit = data.commit {
                // 使用 git diff 输出，而不是纯文本内容对比
                // 这样行号匹配与 GitHub Desktop 完全一致
                self.unifiedDiffText = try project.fileDiff(at: commit.hash, file: file.file)
            } else {
                // 工作区列表已经合并了 staged / unstaged 结果，优先复用当前选中项携带的 patch。
                // 这样新增文件在“已暂存”场景下不会被重新查询成空白。
                if !file.diff.isEmpty {
                    self.unifiedDiffText = file.diff
                } else {
                    self.unifiedDiffText = try project.uncommittedFileDiff(file: file.file)
                }
            }
            self.diffIssueMessage = nil
        } catch {
            os_log(.error, "\(Self.t)❌ 更新差异视图失败: \(error.localizedDescription)")
            alert_error(error)
            self.unifiedDiffText = ""
            self.diffIssueMessage = error.localizedDescription
        }
    }
}

// MARK: - Event

extension FileDetail {
    func onFileChange() {
        self.bg.async {
            updateDiffView(reason: "File Change")
        }
    }

    func onCommitChange() {
        self.bg.async {
            updateDiffView(reason: "Commit Change")
        }
    }

    func onAppear() {
        self.bg.async {
            updateDiffView(reason: "Appear")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
