import Testing
@testable import GitOKUI

struct AppIdentityRowTests {
    @Test
    @MainActor
    func filtersBlankMetadataEntries() {
        let row = AppIdentityRow(title: "GitOK", metadata: ["gpt-5.4", "", "  ", "openai"])

        #expect(row.metadata == ["gpt-5.4", "openai"])
    }
}
