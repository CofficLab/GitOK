import Foundation
import Testing

@Suite("RemoteRepositoryFormRulesTests")
struct RemoteRepositoryFormRulesTests {
    @Test("Normalization trims whitespace from both fields")
    func normalizationTrimsWhitespaceFromBothFields() {
        let input = RemoteRepositoryFormRules.normalizedInput(
            name: "  origin \n",
            url: "  https://github.com/a/b.git \t"
        )

        #expect(input.name == "origin")
        #expect(input.url == "https://github.com/a/b.git")
    }

    @Test("Form validity requires both normalized fields")
    func formValidityRequiresBothNormalizedFields() {
        #expect(RemoteRepositoryFormRules.isFormValid(name: "origin", url: "https://github.com/a/b.git"))
        #expect(!RemoteRepositoryFormRules.isFormValid(name: "   ", url: "https://github.com/a/b.git"))
        #expect(!RemoteRepositoryFormRules.isFormValid(name: "origin", url: " \n "))
    }

    @Test("Change detection compares normalized edits against stored values")
    func changeDetectionComparesNormalizedEditsAgainstStoredValues() {
        #expect(!RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: " origin ",
            editedURL: "https://github.com/a/b.git\n"
        ))
        #expect(RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: "upstream",
            editedURL: "https://github.com/a/b.git"
        ))
        #expect(RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: "origin",
            editedURL: "https://github.com/c/d.git"
        ))
    }
}
