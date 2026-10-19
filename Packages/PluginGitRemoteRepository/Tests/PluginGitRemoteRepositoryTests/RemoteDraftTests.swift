import Foundation
import Testing

@testable import PluginGitRemoteRepository

@Suite("RemoteDraft")
struct RemoteDraftTests {

    @Test("默认草稿名为 origin 且 URL 为空")
    func defaultDraft() {
        let draft = RemoteDraft()

        #expect(draft.name == "origin")
        #expect(draft.url == "")
        #expect(RemoteDraft.defaultName == "origin")
    }

    @Test("URL 为空时不可提交")
    func invalidWhenURLEmpty() {
        let draft = RemoteDraft()

        #expect(draft.isValid == false)
    }

    @Test("URL 仅含空白时不可提交")
    func invalidWhenURLIsBlank() {
        let draft = RemoteDraft(url: "   \n\t  ")

        #expect(draft.trimmedURL.isEmpty)
        #expect(draft.isValid == false)
    }

    @Test("URL 非空时可提交")
    func validWhenURLPresent() {
        let draft = RemoteDraft(url: "https://example.com/a.git")

        #expect(draft.isValid)
    }

    @Test("名称 trim 掉首尾空白")
    func trimsName() {
        let draft = RemoteDraft(name: "  upstream  ", url: "https://example.com/a.git")

        #expect(draft.trimmedName == "upstream")
    }

    @Test("URL trim 掉首尾空白")
    func trimsURL() {
        let draft = RemoteDraft(url: "  https://example.com/a.git \n")

        #expect(draft.trimmedURL == "https://example.com/a.git")
    }

    @Test("原始输入保持不变，trim 只影响派生值")
    func keepsRawInput() {
        let draft = RemoteDraft(name: "  origin  ", url: "  https://example.com/a.git  ")

        #expect(draft.name == "  origin  ")
        #expect(draft.url == "  https://example.com/a.git  ")
        #expect(draft.trimmedName == "origin")
        #expect(draft.trimmedURL == "https://example.com/a.git")
    }

    @Test("submission 返回 trim 后的名称与 URL")
    func submissionIsTrimmed() {
        let draft = RemoteDraft(name: "  upstream ", url: " https://example.com/a.git ")

        let submission = draft.submission

        #expect(submission.name == "upstream")
        #expect(submission.url == "https://example.com/a.git")
    }

    @Test("纯空白名称 trim 后为空，但 URL 有效时仍可提交")
    func blankNameStillSubmittableWithValidURL() {
        let draft = RemoteDraft(name: "   ", url: "https://example.com/a.git")

        #expect(draft.isValid)
        #expect(draft.submission.name.isEmpty)
    }

    @Test("支持自定义初始化")
    func customInit() {
        let draft = RemoteDraft(name: "fork", url: "https://example.com/fork.git")

        #expect(draft.name == "fork")
        #expect(draft.url == "https://example.com/fork.git")
        #expect(draft.isValid)
    }

    @Test("草稿支持相等比较")
    func equatable() {
        let a = RemoteDraft(name: "origin", url: "https://example.com/a.git")
        let b = RemoteDraft(name: "origin", url: "https://example.com/a.git")
        let c = RemoteDraft(name: "fork", url: "https://example.com/a.git")

        #expect(a == b)
        #expect(a != c)
    }
}
