import Foundation

/// PDF 对比预览的版本状态。
///
/// 把「有哪些版本 / 默认展示哪个 / 是否提供版本切换」这组判断从视图里
/// 抽出来，使其可被单元测试覆盖。
struct GitPDFComparisonState: Equatable {
    /// 当前 commit 中的文件内容（文件被删除时为 nil）。
    let current: Data?
    /// 父 commit 中的文件内容（文件是新增时为 nil）。
    let previous: Data?

    init(current: Data?, previous: Data?) {
        self.current = current
        self.previous = previous
    }

    /// 默认是否展示父提交版本。
    ///
    /// 当前实现恒为 `false`（总是优先展示新版本）。
    var showsPreviousByDefault: Bool { false }

    /// 是否渲染版本切换控件。
    ///
    /// 当前实现要求两个版本同时存在才提供切换。
    var showsVersionSwitcher: Bool { current != nil && previous != nil }
}
