import Foundation

/// 添加远程仓库表单的输入草稿与校验。
///
/// 视图只负责展示与绑定文本；trim、默认名与「是否可以提交」的判定
/// 都在此纯类型内，便于单测。
struct RemoteDraft: Equatable {
    /// 新建远程时的默认名称。
    static let defaultName = "origin"

    /// 远程名称（原始输入，未 trim）。
    var name: String = RemoteDraft.defaultName

    /// 远程仓库 URL（原始输入，未 trim）。
    var url: String = ""

    init(name: String = RemoteDraft.defaultName, url: String = "") {
        self.name = name
        self.url = url
    }

    /// trim 空白后的远程名称。
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// trim 空白后的仓库 URL。
    var trimmedURL: String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 是否可以提交：URL 非空即可（名称保持默认或用户输入）。
    var isValid: Bool { !trimmedURL.isEmpty }

    /// 提交给 Git 的参数；调用前应先检查 `isValid`。
    var submission: (name: String, url: String) {
        (trimmedName, trimmedURL)
    }
}
