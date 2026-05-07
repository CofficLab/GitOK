import Foundation
import XCTest

final class BannerRepositoryIndexTests: XCTestCase {
    func testJSONFileURLsSkipsMissingDirectoryAndNonJSONFiles() throws {
        let directory = try makeTemporaryDirectory()
        XCTAssertEqual(BannerRepositoryIndex.jsonFileURLs(in: directory.appendingPathComponent("missing")), [])

        try "{}".write(to: directory.appendingPathComponent("b.json"), atomically: true, encoding: .utf8)
        try "{}".write(to: directory.appendingPathComponent("a.json"), atomically: true, encoding: .utf8)
        try "ignore".write(to: directory.appendingPathComponent("note.txt"), atomically: true, encoding: .utf8)

        let fileNames = BannerRepositoryIndex.jsonFileURLs(in: directory).map(\.lastPathComponent)
        XCTAssertEqual(fileNames, ["a.json", "b.json"])
    }

    func testLoadModelsSkipsFailedLoadsAndUsesProvidedSort() throws {
        let directory = try makeTemporaryDirectory()
        try "{}".write(to: directory.appendingPathComponent("first.json"), atomically: true, encoding: .utf8)
        try "{}".write(to: directory.appendingPathComponent("broken.json"), atomically: true, encoding: .utf8)
        try "{}".write(to: directory.appendingPathComponent("second.json"), atomically: true, encoding: .utf8)

        let models = BannerRepositoryIndex.loadModels(
            from: directory,
            load: { url in
                switch url.deletingPathExtension().lastPathComponent {
                case "first":
                    return BannerRepositoryIndexModel(id: "b")
                case "second":
                    return BannerRepositoryIndexModel(id: "a")
                default:
                    return nil
                }
            },
            sort: { $0.id < $1.id }
        )

        XCTAssertEqual(models, [BannerRepositoryIndexModel(id: "a"), BannerRepositoryIndexModel(id: "b")])
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}

private struct BannerRepositoryIndexModel: Equatable {
    let id: String
}
