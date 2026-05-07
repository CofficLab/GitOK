import Foundation

enum RemoteRepositoryFormRules {
    static func normalizedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedInput(name: String, url: String) -> (name: String, url: String) {
        (
            name: normalizedValue(name),
            url: normalizedValue(url)
        )
    }

    static func isFormValid(name: String, url: String) -> Bool {
        let input = normalizedInput(name: name, url: url)
        return !input.name.isEmpty && !input.url.isEmpty
    }

    static func hasChanges(
        originalName: String,
        originalURL: String,
        editedName: String,
        editedURL: String
    ) -> Bool {
        let input = normalizedInput(name: editedName, url: editedURL)
        return input.name != originalName || input.url != originalURL
    }
}
