import AppKit
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 文件状态显示组件：显示单个文件的Git状态和操作选项
struct FileTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// Git 差异文件对象
    var file: GitDiffFile

    /// 环境对象
    @EnvironmentObject var vm: ProjectVM

    /// 丢弃更改的回调函数
    var onDiscardChanges: ((GitDiffFile) -> Void)?

    var stageState: FileStageState = .unstaged

    var showsStageBadge = true

    var onStage: ((GitDiffFile) -> Void)?

    var onUnstage: ((GitDiffFile) -> Void)?

    var onSelect: ((GitDiffFile) -> Void)?

    var onHoverChanged: ((Bool) -> Void)?

    /// 是否显示详细信息弹窗
    @State var isPresented: Bool = false

    /// 是否显示丢弃更改确认对话框
    @State private var showDiscardAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Text(file.file)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer()

            if showsStageBadge {
                stageBadge
            }
            statusIcon
        }
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

                if isAppInstalled(at: "/Applications/Cursor.app") {
                    Button("在 Cursor 中打开") {
                        openFileInApp(at: "/Applications/Cursor.app")
                    }
                }

                if isAppInstalled(at: "/Applications/Visual Studio Code.app") {
                    Button("在 VS Code 中打开") {
                        openFileInApp(at: "/Applications/Visual Studio Code.app")
                    }
                }

                if isAppInstalled(at: "/Applications/Xcode.app") {
                    Button("在 Xcode 中打开") {
                        openFileInApp(at: "/Applications/Xcode.app")
                    }
                }
            }

            if onDiscardChanges != nil {
                Button("丢弃更改") {
                    showDiscardAlert = true
                }
            }

            if stageState.canStage, let onStage {
                Button("暂存文件") {
                    onStage(file)
                }
            }

            if stageState.canUnstage, let onUnstage {
                Button("取消暂存") {
                    onUnstage(file)
                }
            }
        }
        .alert("确认丢弃更改", isPresented: $showDiscardAlert) {
            Button("取消", role: .cancel) { }
            Button("丢弃", role: .destructive) {
                if let onDiscardChanges = onDiscardChanges {
                    onDiscardChanges(file)
                }
            }
        } message: {
            Text(discardAlertMessage)
        }
        .onDrag {
            filePathItemProvider()
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                onSelect?(file)
            }
        )
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
    }

    /// 文件状态图标视图：根据文件变更类型显示对应的图标和颜色
    private var statusIcon: some View {
        let (icon, color) = iconInfo(for: file.changeType)
        return Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(2)
            .cornerRadius(6)
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
    }

    private var discardAlertMessage: String {
        let normalizedChange = file.changeType.uppercased()
        let deletesWorkingTreeFile = normalizedChange == "?" || normalizedChange == "UNTRACKED" || normalizedChange == "A"

        if deletesWorkingTreeFile {
            return "确定要丢弃文件 \"\(file.file)\" 吗？新文件会从工作区删除，此操作不可撤销。"
        }

        if stageState == .stagedAndUnstaged {
            return "确定要丢弃文件 \"\(file.file)\" 的更改吗？已暂存和未暂存的更改都会被恢复，此操作不可撤销。"
        }

        if stageState == .staged {
            return "确定要丢弃文件 \"\(file.file)\" 的已暂存更改吗？此操作不可撤销。"
        }

        return "确定要丢弃文件 \"\(file.file)\" 的更改吗？此操作不可撤销。"
    }

    /// 获取文件变更类型的图标和颜色信息
    /// - Parameter change: 文件变更类型字符串
    /// - Returns: 返回图标名称和对应颜色的元组
    private func iconInfo(for change: String) -> (String, Color) {
        let normalizedChange = change.uppercased()
        switch normalizedChange {
        case "M", "MODIFIED":
            return (.iconEditCircle, .orange)
        case "A", "ADDED", "NEW":
            return (.iconPlus, .green)
        case "D", "DELETED":
            return (.iconMinus, .red)
        case "R", "RENAMED":
            return (.iconEditCircle, .blue)
        case "C", "COPIED":
            return (.iconEditCircle, .purple)
        case "?", "UNTRACKED":
            return (.iconPlus, .gray)
        default:
            if Self.verbose {
                os_log(.info, "\(self.t)Unknown change type: '\(change)'")
            }
            return (.iconInfo, .gray)
        }
    }

    private var targetFileURL: URL? {
        guard let project = vm.project else { return nil }
        return URL(fileURLWithPath: file.file, relativeTo: project.url).standardizedFileURL
    }

    private var displayFilePath: String {
        targetFileURL?.path ?? file.file
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
        alert_info("已复制路径")
    }

    private func isAppInstalled(at path: String) -> Bool {
        NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: path)) != nil
    }

    private func openFileInApp(at appPath: String) {
        guard let url = targetFileURL,
              targetFileExists,
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: appPath)) else {
            return
        }

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }

    private func filePathItemProvider() -> NSItemProvider {
        let provider = NSItemProvider(object: displayFilePath as NSString)
        if let url = targetFileURL {
            provider.registerObject(url as NSURL, visibility: .all)
        }
        return provider
    }
}

enum FileStageState: Equatable {
    case unstaged
    case staged
    case stagedAndUnstaged

    var title: String {
        switch self {
        case .unstaged: return "未暂存"
        case .staged: return "已暂存"
        case .stagedAndUnstaged: return "部分暂存"
        }
    }

    var color: Color {
        switch self {
        case .unstaged: return .secondary
        case .staged: return .green
        case .stagedAndUnstaged: return .orange
        }
    }

    var canStage: Bool {
        self == .unstaged || self == .stagedAndUnstaged
    }

    var canUnstage: Bool {
        self == .staged || self == .stagedAndUnstaged
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
