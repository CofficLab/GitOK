import Foundation

/// PDF 对比预览视图的 identity。
///
/// `GitPDFComparisonPreview` 用 `@State` 保存「当前展示哪个版本」。
/// SwiftUI 只在视图 identity 变化时才重建 `@State`，而 diff 面板对所有
/// PDF 都渲染同一个分支，因此从「被删除的 PDF」切到「修改过的 PDF」时
/// `@State` 会被沿用。
///
/// 后果：被删除的 PDF 默认展示旧版本（`showingPrevious = true`），
/// 切到两个版本都存在的文件后仍然展示旧版本，与预期相反。
///
/// 把 identity 绑定到「文件路径 + 各版本是否存在」，即可在内容变化时
/// 强制重建视图，让 `@State` 重新按新内容取默认值。
struct PDFPreviewIdentity: Hashable {
    let path: String
    let hasCurrent: Bool
    let hasPrevious: Bool
}
