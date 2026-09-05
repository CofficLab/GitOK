import AppKit
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PluginIcon

@Suite("IconExporter")
struct IconExporterTests {
    @Test("default AppIcon slots include the universal 1024px source")
    func defaultSlotsContainSourceSize() {
        #expect(IconExporter.defaultSlots.contains { $0.pixelSize == 1024 })
        #expect(IconExporter.defaultSlots.last?.filename == "icon-1024.png")
    }

    @Test("exports edited icon settings into a readable AppIcon set")
    func exportsEditedIconSettings() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginIconTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let sourceURL = root.appendingPathComponent("source.png")
        let destinationURL = root.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
        try makeSourceImage(at: sourceURL)

        let icon = IconData(
            backgroundId: "2",
            imageURL: sourceURL,
            path: "",
            opacity: 0.8,
            scale: 0.75,
            cornerRadius: 24,
            padding: 0.1
        )
        try IconExporter.exportAppIcon(from: icon, to: destinationURL)

        let output = try Data(contentsOf: destinationURL.appendingPathComponent("icon-1024.png"))
        let contents = try JSONSerialization.jsonObject(
            with: Data(contentsOf: destinationURL.appendingPathComponent("Contents.json"))
        ) as? [String: Any]

        #expect(output.count > 100)
        #expect((contents?["images"] as? [[String: Any]])?.count == IconExporter.defaultSlots.count)
    }

    private func makeSourceImage(at url: URL) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 64,
            height: 64,
            bitsPerComponent: 8,
            bytesPerRow: 64 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "PluginIconTests", code: 1)
        }
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }
}
