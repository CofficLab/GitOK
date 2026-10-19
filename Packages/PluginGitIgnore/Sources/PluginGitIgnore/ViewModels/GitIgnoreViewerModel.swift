import Foundation
import Observation

/// `.gitignore` 查看器的加载状态。
///
/// View 只读取 `content` / `isLoading` 并渲染，把「读文件 → 结束加载态」
/// 的时序从 SwiftUI `@State` + `Task.detached` 里搬出来，便于单测。
@MainActor
@Observable
final class GitIgnoreViewerModel {
    /// 是否仍在加载（View 据此在骨架屏与内容之间切换）。
    private(set) var isLoading = true

    /// 已加载的 `.gitignore` 内容；加载失败或无仓库时为空字符串。
    private(set) var content = ""

    private let file: GitIgnoreFile

    init(file: GitIgnoreFile) {
        self.file = file
    }

    /// 加载 `.gitignore` 内容并结束加载态。
    ///
    /// 幂等：可被 `.onAppear` 重复调用，每次都基于当前仓库根目录重新读取。
    func load() async {
        let file = self.file
        let text = await Task.detached(priority: .userInitiated) {
            file.read()
        }.value
        content = text
        isLoading = false
    }
}
