import Foundation
import KitGit
import SwiftUI

/// 提交详情插件的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`CommitDetailObserver` 把外部
/// （Provider）事件翻译成本模型的领域方法。视图只绑定本模型，不再直接
/// 读取 Provider 或监听系统通知。
@MainActor
final class CommitDetailViewModel: ObservableObject {
    /// 当前选中的 commit；未选中时为 nil。
    @Published private(set) var selectedCommit: GitCommit?

    /// 当前项目路径（有选中 commit 时即为该 commit 所属项目路径）。
    @Published private(set) var selectedProjectURL: URL?

    /// 当前选中的 commit 内选中的文件路径；未选中文件时为 nil。
    @Published private(set) var selectedFile: String?

    /// 当前展示的 commit 变动文件列表；`nil` 表示尚未加载到任何列表。
    ///
    /// 与 commitlist 的刷新策略一致：加载新 commit 期间**保留上一份列表**
    /// （不清空、不整表闪烁），新数据到达后再动画替换。
    @Published private(set) var currentCommitFiles: [GitFileChange]?

    /// 当前 commit 的变动文件是否正在加载。
    @Published private(set) var isLoadingCommitFiles = false

    /// 当前 commit 变动文件加载失败的错误描述（成功 / 未加载时为 nil）。
    @Published private(set) var commitFilesLoadError: String?

    /// 当前展示的变动文件所属 commit hash。
    ///
    /// 用于区分「跨 commit 切换」与「同 commit 刷新」：前者整表替换、
    /// 全部行播放进入动画；后者只对新增行播放动画，既有行保持原位不闪。
    @Published private(set) var filesCommitHash: String?

    /// 本次刷新新增的文件路径，只用于触发行级进入动画
    /// （对应 commitlist 的 `animatedCommitHashes`）。
    @Published private(set) var animatedFilePaths: Set<String> = []

    /// 变动文件落地序号：只接受最后一次结果，并用于失效过期的动画清理任务。
    private var filesRefreshToken = 0

    /// 仓库数据变化版本号（提交 / 推送 / 分支切换后递增）。
    ///
    /// 工作区变动列表据此强制重载；commit 详情内容不可变，无需重载。
    @Published private(set) var worktreeRevision = 0

    /// 外部项目 / 选中状态变化 → 同步最新值。
    func handleSelectionChanged(commit: GitCommit?, projectURL: URL?, file: String?) {
        selectedCommit = commit
        selectedProjectURL = projectURL
        selectedFile = file
        if commit == nil {
            // 退出 commit 详情（工作区模式）：清空上一 commit 的变动文件，
            // 避免残留；在途加载结果与过期动画任务一并失效。
            currentCommitFiles = nil
            filesCommitHash = nil
            animatedFilePaths = []
            isLoadingCommitFiles = false
            commitFilesLoadError = nil
            filesRefreshToken &+= 1
        }
    }

    /// 外部 commit 变动文件状态变化 → 同步最新值。
    ///
    /// 刷新策略对齐 commitlist（参考 `CommitRailView`）：
    /// - 加载期间（`files == nil`）保留上一份列表，由视图显示顶部细进度条，
    ///   不整表闪烁；
    /// - 新数据到达时按 path 增量识别新行：跨 commit 切换整表替换（全部行
    ///   播放从顶部滑入动画），同 commit 刷新只对新增行播放动画；
    /// - 首次加载（此前无任何数据）不播放动画，直接呈现。
    func handleCommitFilesChanged(
        files: [GitFileChange]?,
        isLoading: Bool,
        loadError: String?,
        commitHash: String?
    ) {
        isLoadingCommitFiles = isLoading
        commitFilesLoadError = loadError
        guard let files else { return }

        let previous = currentCommitFiles
        let inserted = CommitFilesRefreshPolicy.insertedFilePaths(previous: previous ?? [], current: files)
        let isSameCommitRefresh = filesCommitHash != nil && filesCommitHash == commitHash
        // 跨 commit 切换：新旧列表无行级延续性，整表替换时全部行视为新增。
        let isCommitSwitch = filesCommitHash != nil && filesCommitHash != commitHash
        // 仅「旧列表与新列表都非空」的替换播放动画：首次加载 / 切换到空结果
        // （空列表、加载失败）直接呈现，避免空状态也参与行级动效。
        let shouldAnimate = previous?.isEmpty == false && !files.isEmpty
            && (isSameCommitRefresh || isCommitSwitch)

        filesRefreshToken &+= 1
        let refreshToken = filesRefreshToken
        filesCommitHash = commitHash

        if shouldAnimate {
            animatedFilePaths = isSameCommitRefresh ? inserted : Set(files.lazy.map(\.path))
            withAnimation(.snappy(duration: 0.38)) {
                currentCommitFiles = files
            }
            let animationToken = refreshToken
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard animationToken == filesRefreshToken else { return }
                animatedFilePaths = []
            }
        } else {
            animatedFilePaths = []
            currentCommitFiles = files
        }
    }

    /// 外部仓库数据变化（提交 / 推送 / 分支切换）→ 通知工作区视图重载。
    func handleProjectDataChanged() {
        worktreeRevision &+= 1
    }
}

/// Commit 变动文件刷新时的纯数据判断，供 UI 增量更新和测试复用。
enum CommitFilesRefreshPolicy {
    static func insertedFilePaths(previous: [GitFileChange], current: [GitFileChange]) -> Set<String> {
        let previousPaths = Set(previous.map(\.path))
        return Set(current.lazy.map(\.path)).subtracting(previousPaths)
    }
}
