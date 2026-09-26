import Foundation
import Testing
@testable import ProviderCoAuthor

@Suite("CoAuthor formatting")
struct CoAuthorFormattingTests {
    @Test("coAuthoredByLine formats trailer")
    func coAuthoredByLine() {
        let author = CoAuthor(name: "Alice", email: "alice@example.com")
        #expect(author.coAuthoredByLine == "Co-authored-by: Alice <alice@example.com>")
    }

    @Test("displayText formats name and email")
    func displayText() {
        let author = CoAuthor(name: "Alice", email: "alice@example.com")
        #expect(author.displayText == "Alice <alice@example.com>")
    }

    @Test("init assigns fields")
    func initAssigns() {
        let id = UUID()
        let author = CoAuthor(id: id, name: "Bob", email: "bob@example.com")
        #expect(author.id == id)
        #expect(author.name == "Bob")
        #expect(author.email == "bob@example.com")
    }
}
