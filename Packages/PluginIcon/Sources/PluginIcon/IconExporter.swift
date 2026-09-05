import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum IconExporter {
    public struct Slot: Codable, Equatable, Sendable {
        public let filename: String
        public let idiom: String
        public let size: String
        public let scale: String
        public let pixelSize: Int

        public init(filename: String, idiom: String, size: String, scale: String, pixelSize: Int) {
            self.filename = filename
            self.idiom = idiom
            self.size = size
            self.scale = scale
            self.pixelSize = pixelSize
        }
    }

    public static let defaultSlots = [
        Slot(filename: "icon-20@2x.png", idiom: "universal", size: "20x20", scale: "2x", pixelSize: 40),
        Slot(filename: "icon-29@2x.png", idiom: "universal", size: "29x29", scale: "2x", pixelSize: 58),
        Slot(filename: "icon-40@2x.png", idiom: "universal", size: "40x40", scale: "2x", pixelSize: 80),
        Slot(filename: "icon-60@2x.png", idiom: "universal", size: "60x60", scale: "2x", pixelSize: 120),
        Slot(filename: "icon-1024.png", idiom: "universal", size: "1024x1024", scale: "1x", pixelSize: 1024),
    ]

    public static func exportAppIcon(
        from sourceURL: URL,
        to destinationURL: URL,
        slots: [Slot] = defaultSlots,
        fileManager: FileManager = .default
    ) throws {
        guard let image = NSImage(contentsOf: sourceURL),
              let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw IconExportError.invalidSourceImage
        }

        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        for slot in slots {
            let outputURL = destinationURL.appendingPathComponent(slot.filename)
            try writePNG(sourceImage, pixelSize: slot.pixelSize, to: outputURL)
        }

        let contents: [String: Any] = [
            "images": slots.map {
                ["filename": $0.filename, "idiom": $0.idiom, "scale": $0.scale, "size": $0.size]
            },
            "info": ["author": "xcode", "version": 1],
        ]
        let data = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: destinationURL.appendingPathComponent("Contents.json"), options: [.atomic])
    }

    private static func writePNG(_ image: CGImage, pixelSize: Int, to url: URL) throws {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: pixelSize,
                  height: pixelSize,
                  bitsPerComponent: 8,
                  bytesPerRow: pixelSize * 4,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let destination = CGImageDestinationCreateWithURL(
                  url as CFURL,
                  UTType.png.identifier as CFString,
                  1,
                  nil
              ) else {
            throw IconExportError.cannotCreateImageContext
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        guard let outputImage = context.makeImage() else {
            throw IconExportError.cannotCreateImageContext
        }
        CGImageDestinationAddImage(destination, outputImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw IconExportError.writeFailed
        }
    }
}

public enum IconExportError: Error, LocalizedError {
    case invalidSourceImage
    case cannotCreateImageContext
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSourceImage: "The selected file is not a readable image."
        case .cannotCreateImageContext: "Unable to create an icon image context."
        case .writeFailed: "Unable to write the generated icon image."
        }
    }
}
