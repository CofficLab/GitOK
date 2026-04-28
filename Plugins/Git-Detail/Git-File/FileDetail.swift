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
                    MagicDiffView(diffOutput: unifiedDiffText)
                        .background(.background)
                }
            }
        }
        .onChange(of: vm.file, onFileChange)
        .onChange(of: data.commit, onCommitChange)
        .onAppear(perform: onAppear)
        .frame(maxHeight: .infinity)
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
            return
        }

        do {
            if let commit = data.commit {
                // 使用 git diff 输出，而不是纯文本内容对比
                // 这样行号匹配与 GitHub Desktop 完全一致
                self.unifiedDiffText = try project.fileDiff(at: commit.hash, file: file.file)
            } else {
                // 未提交的变更也使用 git diff 输出
                self.unifiedDiffText = try project.uncommittedFileDiff(file: file.file)
            }
        } catch {
            os_log(.error, "\(Self.t)❌ 更新差异视图失败: \(error.localizedDescription)")
            alert_error(error)
            self.unifiedDiffText = ""
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
