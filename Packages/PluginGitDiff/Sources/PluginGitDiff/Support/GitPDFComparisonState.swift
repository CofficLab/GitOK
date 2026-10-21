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
    /// 只有「删除前」一个版本时必须展示它，否则正文恒为
    /// 「PDF Preview Unavailable」；两个版本都在时仍优先展示新版本。
    var showsPreviousByDefault: Bool { current == nil && previous != nil }

    /// 是否渲染版本切换控件。
    ///
    /// 只要存在可展示的版本就提供切换：删除场景下只有一个版本时，
    /// 控件同样可用，避免用户以为预览无法显示。
    var showsVersionSwitcher: Bool { current != nil || previous != nil }
}
