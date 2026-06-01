import AppKit
import SwiftUI

public struct GitDetailFileItem: Equatable, Sendable {
    public let path: String
    public let changeType: String

    public init(path: String, changeType: String) {
        self.path = path
        self.changeType = changeType
    }
}

/// 文件状态显示组件：显示单个文件的 Git 状态和操作选项。
public struct FileTile: View {
    public nonisolated static let verbose = false

    private let file: GitDetailFileItem
    private let projectURL: URL?
    private let onDiscardChanges: (() -> Void)?
    private let stageState: FileStageState
    private let showsStageBadge: Bool
    private let isBatchSelected: Bool
    private let onToggleBatchSelection: (() -> Void)?
    private let onStage: (() -> Void)?
    private let onUnstage: (() -> Void)?
    private let onSelect: (() -> Void)?
    private let onHoverChanged: ((Bool) -> Void)?

    @State private var showDiscardAlert = false

    public init(
        file: GitDetailFileItem,
        projectURL: URL?,
        onDiscardChanges: (() -> Void)? = nil,
        stageState: FileStageState = .unstaged,
        showsStageBadge: Bool = true,
        isBatchSelected: Bool = false,
        onToggleBatchSelection: (() -> Void)? = nil,
        onStage: (() -> Void)? = nil,
        onUnstage: (() -> Void)? = nil,
        onSelect: (() -> Void)? = nil,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.file = file
        self.projectURL = projectURL
        self.onDiscardChanges = onDiscardChanges
        self.stageState = stageState
        self.showsStageBadge = showsStageBadge
        self.isBatchSelected = isBatchSelected
        self.onToggleBatchSelection = onToggleBatchSelection
        self.onStage = onStage
        self.onUnstage = onUnstage
        self.onSelect = onSelect
        self.onHoverChanged = onHoverChanged
    }

    public var body: some View {
        HStack(spacing: 12) {
            if onToggleBatchSelection != nil {
                Button {
                    onToggleBatchSelection?()
                } label: {
                    Image(systemName: isBatchSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBatchSelected ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(isBatchSelected ? "取消选择" : "选择文件")
                .accessibilityLabel(isBatchSelected ? "取消选择 \(file.path)" : "选择 \(file.path)")
                .accessibilityHint("用于批量暂存、取消暂存或丢弃")
            }

            Text(file.path)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer()

            if showsStageBadge {
                stageBadge
            }
            statusIcon
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("按回车或点击查看差异。打开上下文菜单可暂存、取消暂存、复制路径或丢弃更改。")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .contextMenu {
            if targetFileExists {
                Button("在Finder中显示") {
                    revealInFinder()
                }

                Button("复制文件路径") {
                    copyFilePath()
                }

            }

            if onDiscardChanges != nil {
                Button("丢弃更改") {
                    showDiscardAlert = true
                }
            }

            if stageState.canStage, let onStage {
                Button("暂存文件") {
                    onStage()
                }
            }

            if stageState.canUnstage, let onUnstage {
                Button("取消暂存") {
                    onUnstage()
                }
            }
        }
        .alert("确认丢弃更改", isPresented: $showDiscardAlert) {
            Button("取消", role: .cancel) { }
            Button("丢弃", role: .destructive) {
                onDiscardChanges?()
            }
        } message: {
            Text(discardAlertMessage)
        }
        .onDrag {
            filePathItemProvider()
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                onSelect?()
            }
        )
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
    }

    private var statusIcon: some View {
        let (icon, color) = iconInfo(for: file.changeType)
        return Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(2)
            .cornerRadius(6)
            .accessibilityHidden(true)
    }

    private var stageBadge: some View {
        Text(stageState.title)
            .font(.caption2)
            .foregroundColor(stageState.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(stageState.color.opacity(0.12))
            )
            .accessibilityHidden(true)
    }

    private var accessibilitySummary: String {
        var parts = [
            file.path,
            changeTypeAccessibilityLabel,
        ]

        if showsStageBadge {
            parts.append(stageState.title)
        }

        if isBatchSelected {
            parts.append("已加入批量选择")
        }

        return parts.joined(separator: "，")
    }

    private var changeTypeAccessibilityLabel: String {
        switch file.changeType.uppercased() {
        case "M", "MODIFIED":
            return "已修改"
        case "A", "ADDED", "NEW":
            return "新增"
        case "D", "DELETED":
            return "已删除"
        case "R", "RENAMED":
            return "已重命名"
        case "C", "COPIED":
            return "已复制"
        case "?", "UNTRACKED":
            return "未跟踪"
        default:
            return "状态 \(file.changeType)"
        }
    }

    private var discardAlertMessage: String {
        let normalizedChange = file.changeType.uppercased()
        let deletesWorkingTreeFile = normalizedChange == "?" || normalizedChange == "UNTRACKED" || normalizedChange == "A"

        if deletesWorkingTreeFile {
            return "确定要丢弃文件 \"\(file.path)\" 吗？新文件会从工作区删除，此操作不可撤销。"
        }

        if stageState == .stagedAndUnstaged {
            return "确定要丢弃文件 \"\(file.path)\" 的更改吗？已暂存和未暂存的更改都会被恢复，此操作不可撤销。"
        }

        if stageState == .staged {
            return "确定要丢弃文件 \"\(file.path)\" 的已暂存更改吗？此操作不可撤销。"
        }

        return "确定要丢弃文件 \"\(file.path)\" 的更改吗？此操作不可撤销。"
    }

    private func iconInfo(for change: String) -> (String, Color) {
        let normalizedChange = change.uppercased()
        switch normalizedChange {
        case "M", "MODIFIED":
            return ("pencil.circle", .orange)
        case "A", "ADDED", "NEW":
            return ("plus", .green)
        case "D", "DELETED":
            return ("minus", .red)
        case "R", "RENAMED":
            return ("pencil.circle", .blue)
        case "C", "COPIED":
            return ("pencil.circle", .purple)
        case "?", "UNTRACKED":
            return ("plus", .gray)
        default:
            return ("info.circle", .gray)
        }
    }

    private var targetFileURL: URL? {
        guard let projectURL else { return nil }
        return URL(fileURLWithPath: file.path, relativeTo: projectURL).standardizedFileURL
    }

    private var displayFilePath: String {
        targetFileURL?.path ?? file.path
    }

    private var targetFileExists: Bool {
        guard let url = targetFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    private func revealInFinder() {
        guard let url = targetFileURL, targetFileExists else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func copyFilePath() {
        guard let url = targetFileURL, targetFileExists else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }

    private func filePathItemProvider() -> NSItemProvider {
        let provider = NSItemProvider(object: displayFilePath as NSString)
        if let url = targetFileURL {
            provider.registerObject(url as NSURL, visibility: .all)
        }
        return provider
    }
}

public enum FileStageState: Equatable, Sendable {
    case unstaged
    case staged
    case stagedAndUnstaged

    public var title: String {
        switch self {
        case .unstaged: return "未暂存"
        case .staged: return "已暂存"
        case .stagedAndUnstaged: return "部分暂存"
        }
    }

    public var color: Color {
        switch self {
        case .unstaged: return .secondary
        case .staged: return .green
        case .stagedAndUnstaged: return .orange
        }
    }

    public var canStage: Bool {
        self == .unstaged || self == .stagedAndUnstaged
    }

    public var canUnstage: Bool {
        self == .staged || self == .stagedAndUnstaged
    }
}
