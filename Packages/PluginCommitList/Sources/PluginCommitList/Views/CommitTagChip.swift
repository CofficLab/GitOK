import AppKit
import KitGit
import LumiUI
import SwiftUI

/// commit 行里的 tag 胶囊。
///
/// 行内宽度有限，tag 名经常被截断（`backup/dev-…`）；点击胶囊展开 popover，
/// 展示完整 tag 名、类型、指向的提交、创建信息，以及该提交上的全部 tag。
struct CommitTagChip: View {
    /// 胶囊上显示的 tag 名。
    let tag: String
    /// 所在提交的全部 tag（行内最多显示两个，其余在 popover 里补齐）。
    let siblingTags: [String]
    /// 所在提交，用于详情读取失败时兜底展示。
    let commit: GitCommit
    /// 仓库路径；为空时 popover 只展示兜底信息。
    let repository: URL?

    @State private var isPopoverPresented = false

    var body: some View {
        Button {
            isPopoverPresented = true
        } label: {
            AppTag(tag, systemImage: "tag", style: .accent)
        }
        .buttonStyle(.plain)
        .help(pluginLocalization.string("Click to see tag details"))
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            CommitTagDetailPopover(
                tag: tag,
                siblingTags: siblingTags,
                commit: commit,
                repository: repository
            )
        }
    }
}

/// tag 详情弹层。
///
/// 内容来自 `GitTagReader` 的本地读取（只读，不写仓库）：完整 tag 名、tag 类型、
/// 指向的提交、创建者与说明；详情读取失败时退回到提交本身的信息。
struct CommitTagDetailPopover: View {
    /// 复制动作的目标。
    private enum CopyTarget {
        case tag
        case commit
    }

    /// 打开弹层时选中的 tag。
    let tag: String
    /// 所在提交的全部 tag。
    let siblingTags: [String]
    /// 所在提交。
    let commit: GitCommit
    /// 仓库路径；为空时只展示兜底信息。
    let repository: URL?

    @LumiTheme private var theme
    @State private var selectedTag: String
    @State private var detail: GitTagDetail?
    @State private var isLoading = false
    @State private var copiedTarget: CopyTarget?

    init(
        tag: String,
        siblingTags: [String],
        commit: GitCommit,
        repository: URL?
    ) {
        self.tag = tag
        self.siblingTags = siblingTags
        self.commit = commit
        self.repository = repository
        _selectedTag = State(initialValue: tag)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            details
            if siblingTags.count > 1 {
                Divider()
                siblingSection
            }
            Divider()
            footer
        }
        .frame(width: 340)
        .task(id: loadKey) {
            await loadDetail()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "tag.fill")
                .foregroundStyle(theme.primary)
                .padding(.top, 2)
            Text(selectedTag)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("gitok.git.commit.tag.popover.name")
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: - Details

    @ViewBuilder
    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(pluginLocalization.string("Loading..."))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let detail {
                detailRow(
                    pluginLocalization.string("Type"),
                    detail.kind == .annotated
                        ? pluginLocalization.string("Annotated tag")
                        : pluginLocalization.string("Lightweight tag"),
                    identifier: "gitok.git.commit.tag.popover.type"
                )
                detailRow(
                    pluginLocalization.string("Points to"),
                    "\(String(detail.targetHash.prefix(7)))  \(detail.targetSubject)",
                    identifier: "gitok.git.commit.tag.popover.target"
                )
                if let creator = creatorDescription(detail) {
                    detailRow(
                        pluginLocalization.string("Created by"),
                        creator,
                        identifier: "gitok.git.commit.tag.popover.creator"
                    )
                }
                if let date = detail.creatorDate {
                    detailRow(
                        pluginLocalization.string("Created at"),
                        Self.fullDate(date),
                        identifier: "gitok.git.commit.tag.popover.date"
                    )
                }
                if let message = detail.message {
                    detailRow(
                        pluginLocalization.string("Message"),
                        message,
                        identifier: "gitok.git.commit.tag.popover.message"
                    )
                }
            } else {
                detailRow(
                    pluginLocalization.string("Points to"),
                    "\(commit.shortHash)  \(commit.message)",
                    identifier: "gitok.git.commit.tag.popover.target"
                )
                Text(pluginLocalization.string("Tag details are unavailable."))
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private func detailRow(
        _ title: String,
        _ value: String,
        identifier: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(theme.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
            Spacer(minLength: 0)
        }
    }

    /// 创建者描述：附注 tag 展示 tagger，轻量 tag 展示提交作者。
    private func creatorDescription(_ detail: GitTagDetail) -> String? {
        let name = detail.creatorName
        let email = detail.creatorEmail
        switch (name, email) {
        case let (name?, email?):
            return "\(name) <\(email)>"
        case let (name?, nil):
            return name
        case let (nil, email?):
            return email
        case (nil, nil):
            return nil
        }
    }

    // MARK: - Sibling Tags

    private var siblingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            AppSectionLabel(pluginLocalization.string("All tags on this commit"))
            ForEach(siblingTags, id: \.self) { sibling in
                Button {
                    selectedTag = sibling
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sibling == selectedTag ? "checkmark.circle.fill" : "tag")
                            .foregroundStyle(sibling == selectedTag ? theme.primary : theme.textTertiary)
                        Text(sibling)
                            .font(.callout)
                            .foregroundStyle(theme.textPrimary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("gitok.git.commit.tag.popover.sibling.\(sibling)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            AppButton(
                pluginLocalization.string("Copy Tag Name"),
                systemImage: copiedTarget == .tag ? "checkmark" : "doc.on.doc",
                style: .secondary,
                size: .small
            ) {
                copy(selectedTag, to: .tag)
            }
            AppButton(
                pluginLocalization.string("Copy Commit Hash"),
                systemImage: copiedTarget == .commit ? "checkmark" : "number",
                style: .secondary,
                size: .small
            ) {
                copy(detail?.targetHash ?? commit.hash, to: .commit)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: - Data

    /// 读取 key：切换 tag 或切换仓库时重新读取详情。
    private var loadKey: String {
        "\(selectedTag)|\(repository?.path ?? "")"
    }

    private func loadDetail() async {
        guard let repository else {
            detail = nil
            isLoading = false
            return
        }
        let tag = selectedTag
        isLoading = true
        let loaded = await Task.detached(priority: .userInitiated) {
            GitTagReader.detail(named: tag, in: repository)
        }.value
        guard selectedTag == tag else { return }
        detail = loaded
        isLoading = false
    }

    private func copy(_ value: String, to target: CopyTarget) {
        guard !value.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copiedTarget = target
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedTarget == target {
                copiedTarget = nil
            }
        }
    }

    private static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
