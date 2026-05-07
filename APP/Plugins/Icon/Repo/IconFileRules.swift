import Foundation

enum IconFileRules {
    static let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]

    static func isSupportedImageFile(_ filename: String) -> Bool {
        let lowercased = filename.lowercased()
        return supportedFormats.contains { lowercased.hasSuffix(".\($0)") }
    }

    static func imageFileURLs(in directory: URL, entries: [String]) -> [URL] {
        entries.compactMap { name in
            guard isSupportedImageFile(name) else { return nil }
            return directory.appendingPathComponent(name)
        }
    }

    static func iconCount(in entries: [String]) -> Int {
        entries.filter(isSupportedImageFile).count
    }

    static func preferredLookupCandidates(for iconId: String) -> [String] {
        if iconId.contains(".") {
            return [iconId]
        }

        return [iconId] + supportedFormats.map { "\(iconId).\($0)" }
    }
}
