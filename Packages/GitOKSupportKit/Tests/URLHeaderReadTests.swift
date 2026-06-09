import Foundation
import XCTest
@testable import GitOKSupportKit

final class URLHeaderReadTests: XCTestCase {
    func testReadFileHeaderReturnsRequestedPrefix() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("blob.bin")
        try Data([0, 1, 2, 3, 4, 5, 6, 7]).write(to: fileURL)

        XCTAssertEqual(fileURL.readFileHeader(length: 3), [0, 1, 2])
        XCTAssertEqual(fileURL.readFileHeader(length: 0), [])
    }
}
