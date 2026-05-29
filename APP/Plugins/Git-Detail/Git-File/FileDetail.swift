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
    @State private var imageDiffMode: ImageDiffMode = .twoUp
    @State private var imageBlendAmount = 0.5

    static let emoji = "🌍"
    private static let maxRenderableDiffCharacters = 500_000

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
        } else if shouldSkipDiffRendering {
            largeDiffView(for: file)
        } else {
            diffViewBody
        }
    }

    @ViewBuilder
    private var diffViewBody: some View {
        MagicDiffView(diffOutput: unifiedDiffText)
            .background(.background)
    }

    private var shouldSkipDiffRendering: Bool {
        unifiedDiffText.count > Self.maxRenderableDiffCharacters
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
            imagePreviewSection(title: String(localized: "New Image"), image: loadImageFromCommit(file: file))
        } else if changeType == "D" {
            // 删除的图片
            imagePreviewSection(title: String(localized: "Deleted Image"), image: loadImageBefore(file: file))
        } else {
            imageComparisonView(
                before: loadImageBefore(file: file),
                after: loadImageFromCommit(file: file)
            )
        }
    }

    private func imageComparisonView(before: NSImage?, after: NSImage?) -> some View {
        VStack(spacing: 0) {
            imageDiffToolbar

            switch imageDiffMode {
            case .twoUp:
                HStack(spacing: 0) {
                    imagePreviewSection(title: String(localized: "Before"), image: before)

                    Divider()

                    imagePreviewSection(title: String(localized: "After"), image: after)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(String(localized: "Image side-by-side comparison"))
            case .swipe:
                imageOverlayComparison(before: before, after: after, mode: .swipe)
            case .onion:
                imageOverlayComparison(before: before, after: after, mode: .onion)
            case .difference:
                imageOverlayComparison(before: before, after: after, mode: .difference)
            }
        }
    }

    private var imageDiffToolbar: some View {
        HStack(spacing: 12) {
            Picker(String(localized: "Image Comparison Mode"), selection: $imageDiffMode) {
                ForEach(ImageDiffMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)
            .accessibilityLabel(String(localized: "Image Comparison Mode"))

            if imageDiffMode.usesBlendAmount {
                Slider(value: $imageBlendAmount, in: 0...1)
                    .frame(width: 160)
                    .accessibilityLabel(imageDiffMode.sliderAccessibilityLabel)

                Text(imageDiffMode.valueLabel(for: imageBlendAmount))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private func imageOverlayComparison(before: NSImage?, after: NSImage?, mode: ImageDiffMode) -> some View {
        if let before, let after {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .leading) {
                        Color(NSColor.textBackgroundColor)

                        imageLayer(before, in: geometry)

                        switch mode {
                        case .swipe:
                            imageLayer(after, in: geometry)
                                .frame(width: max(1, geometry.size.width * imageBlendAmount), alignment: .leading)
                                .clipped()

                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 2)
                                .offset(x: max(0, geometry.size.width * imageBlendAmount - 1))
                        case .onion:
                            imageLayer(after, in: geometry)
                                .opacity(imageBlendAmount)
                        case .difference:
                            imageLayer(after, in: geometry)
                                .blendMode(.difference)
                        case .twoUp:
                            EmptyView()
                        }
                    }
                    .frame(
                        width: max(max(before.size.width, after.size.width), geometry.size.width),
                        height: max(max(before.size.height, after.size.height), geometry.size.height)
                    )
                    .padding(8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mode.accessibilityLabel)
            .accessibilityHint(mode.accessibilityHint)
        } else {
            imagePreview(image: before ?? after)
        }
    }

    private func imageLayer(_ image: NSImage, in geometry: GeometryProxy) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: max(image.size.width, geometry.size.width),
                height: max(image.size.height, geometry.size.height)
            )
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
                Text(String(localized: "Unable to load image"))
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

            Text(String(localized: "Binary File"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(String(localized: "Differences cannot be shown as text for this file"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func largeDiffView(for file: GitDiffFile) -> some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            Text(String(localized: "Diff is too large, rendering skipped"))
                .font(.headline)

            Text(String(localized: "The current diff is approximately \(unifiedDiffText.count.formatted()) characters. To avoid UI lag, GitOK does not render oversized patches directly; you can still copy the raw diff or view the file text."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                Button(String(localized: "Copy Raw Diff")) {
                    copyToPasteboard(unifiedDiffText)
                }

                if hasBeforeText(for: file) {
                    Button(String(localized: "View Original Text")) {
                        presentTextPreview(kind: .before, for: file)
                    }
                }

                if hasAfterText(for: file) {
                    Button(String(localized: "View New Text")) {
                        presentTextPreview(kind: .after, for: file)
                    }
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func emptyDiffView(for file: GitDiffFile) -> some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: diffIssueMessage == nil ? "doc.text.magnifyingglass" : "exclamationmark.triangle")
                .font(.system(size: 34))
                .foregroundColor(diffIssueMessage == nil ? .secondary : .orange)

            Text(diffIssueMessage == nil ? String(localized: "No differences to display") : String(localized: "Unable to display differences"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(emptyDiffExplanation(for: file))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let diffIssueMessage, !diffIssueMessage.isEmpty {
                Text(String(localized: "Reason: \(diffIssueMessage)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Text(String(localized: "File Status: \(changeTypeLabel(for: file))"))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(String(localized: "Refresh")) {
                    refreshDiff()
                }

                if hasBeforeText(for: file) {
                    Button(String(localized: "View Original Text")) {
                        presentTextPreview(kind: .before, for: file)
                    }
                }

                if hasAfterText(for: file) {
                    Button(String(localized: "View New Text")) {
                        presentTextPreview(kind: .after, for: file)
                    }
                }

                if let diffIssueMessage, !diffIssueMessage.isEmpty {
                    Button(String(localized: "Copy Reason")) {
                        copyToPasteboard(diffIssueMessage)
                    }
                }
            }
            .buttonStyle(.bordered)

            Spacer()
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
            return String(localized: "Diff data could not be generated. You can check whether the file still exists, verify it is text-encoded, or refresh the current view.")
        }

        switch file.changeType.uppercased() {
        case "A", "?":
            return String(localized: "No parseable text diff was generated for this new file. Common causes include an empty file, non-text content, or Git not returning a patch. You can still view the new text directly.")
        case "D":
            return String(localized: "No displayable patch was retrieved for this deleted file. Common causes include an empty file or Git not returning a deletion diff. You can still view the text before deletion.")
        default:
            return String(localized: "No text differences to display for this file. It may be unchanged, empty, or the diff output is empty. You can view the original and new text directly to confirm.")
        }
    }

    private func changeTypeLabel(for file: GitDiffFile) -> String {
        switch file.changeType.uppercased() {
        case "A": return String(localized: "Staged New")
        case "?": return String(localized: "Untracked New")
        case "M": return String(localized: "Modified")
        case "D": return String(localized: "Deleted")
        case "R": return String(localized: "Renamed")
        case "C": return String(localized: "Copied")
        case "T": return String(localized: "Type Changed")
        default: return file.changeType
        }
    }

    private enum ImageDiffMode: String, CaseIterable, Identifiable {
        case twoUp
        case swipe
        case onion
        case difference

        var id: String { rawValue }

        var title: String {
            switch self {
            case .twoUp: return String(localized: "Side by Side")
            case .swipe: return String(localized: "Swipe")
            case .onion: return String(localized: "Overlay")
            case .difference: return String(localized: "Difference")
            }
        }

        var usesBlendAmount: Bool {
            switch self {
            case .swipe, .onion:
                return true
            case .twoUp, .difference:
                return false
            }
        }

        var sliderAccessibilityLabel: String {
            switch self {
            case .swipe:
                return String(localized: "Swipe divider position")
            case .onion:
                return String(localized: "Modified image opacity")
            case .twoUp, .difference:
                return ""
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .twoUp:
                return String(localized: "Image side-by-side comparison")
            case .swipe:
                return String(localized: "Image swipe comparison")
            case .onion:
                return String(localized: "Image overlay comparison")
            case .difference:
                return String(localized: "Image difference blend comparison")
            }
        }

        var accessibilityHint: String {
            switch self {
            case .twoUp:
                return String(localized: "Shows the before and after images side by side")
            case .swipe:
                return String(localized: "Use the slider to adjust the position where the modified image overlays the original")
            case .onion:
                return String(localized: "Use the slider to adjust the opacity of the modified image overlaid on the original")
            case .difference:
                return String(localized: "Uses difference blend mode to highlight areas where the two images differ")
            }
        }

        func valueLabel(for value: Double) -> String {
            "\(Int((value * 100).rounded()))%"
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
                let title = kind == .before ? String(localized: "Original Text") : String(localized: "New Text")

                DispatchQueue.main.async {
                    self.textPreviewTitle = "\(title) · \(file.file)"
                    self.textPreviewContent = content
                    self.showTextPreview = true
                }
            } catch {
                let message = String(localized: "Unable to load \(kind == .before ? "original" : "new") text: \(error.localizedDescription)")
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
                throw GitDetailError.fileNotFound("original text does not exist")
            }
            return before.isEmpty ? String(localized: "/* Empty file */") : before
        case .after:
            guard let after = contents.after else {
                throw GitDetailError.fileNotFound("new text does not exist")
            }
            return after.isEmpty ? String(localized: "/* Empty file */") : after
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
