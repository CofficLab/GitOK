import Foundation
import Testing

@Suite("CoAuthorStoreTests")
struct CoAuthorStoreTests {
    private let defaultsKey = "GitOK_CoAuthors"

    @Test("CoAuthor display strings follow expected format")
    func displayStringsFollowExpectedFormat() {
        let author = CoAuthor(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!, name: "Ada", email: "ada@example.com")

        #expect(author.coAuthoredByLine == "Co-authored-by: Ada <ada@example.com>")
        #expect(author.displayText == "Ada <ada@example.com>")
    }

    @Test("Store saves loads deduplicates updates and removes by id")
    func storeSavesLoadsDeduplicatesUpdatesAndRemovesByID() {
        let store = CoAuthorStore.shared
        UserDefaults.standard.removeObject(forKey: defaultsKey)

        let first = CoAuthor(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!, name: "Ada", email: "ada@example.com")
        let duplicateEmail = CoAuthor(id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!, name: "Ada Two", email: "ada@example.com")
        let second = CoAuthor(id: UUID(uuidString: "FFFFFFFF-EEEE-DDDD-CCCC-BBBBBBBBBBBB")!, name: "Linus", email: "linus@example.com")

        store.addCoAuthor(first)
        store.addCoAuthor(duplicateEmail)
        store.addCoAuthor(second)

        #expect(store.loadCoAuthors() == [first, second])

        let updatedSecond = CoAuthor(id: second.id, name: "Linus T", email: "linus@example.com")
        store.updateCoAuthor(updatedSecond)
        #expect(store.loadCoAuthors() == [first, updatedSecond])

        store.removeCoAuthor(first)
        #expect(store.loadCoAuthors() == [updatedSecond])

        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    @Test("Load returns empty array for invalid stored data")
    func loadReturnsEmptyForInvalidStoredData() {
        UserDefaults.standard.set(Data("invalid".utf8), forKey: defaultsKey)
        #expect(CoAuthorStore.shared.loadCoAuthors().isEmpty)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
