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
        let icon = IconData(imageURL: sourceURL, path: "")
        try exportAppIcon(from: icon, to: destinationURL, slots: slots, fileManager: fileManager)
    }

    /// Exports an AppIcon set using the same composition settings shown in the editor.
    public static func exportAppIcon(
        from icon: IconData,
        to destinationURL: URL,
        slots: [Slot] = defaultSlots,
        fileManager: FileManager = .default
    ) throws {
        guard let sourceURL = icon.imageURL,
              let image = NSImage(contentsOf: sourceURL),
              let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw IconExportError.invalidSourceImage
        }

        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        for slot in slots {
            let outputURL = destinationURL.appendingPathComponent(slot.filename)
            try writePNG(sourceImage, icon: icon, pixelSize: slot.pixelSize, to: outputURL)
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

    private static func writePNG(_ image: CGImage, icon: IconData, pixelSize: Int, to url: URL) throws {
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
        drawBackground(for: icon.backgroundId, opacity: icon.opacity, in: context, size: pixelSize)

        let padding = min(max(icon.padding, 0), 0.45)
        let scale = max(icon.scale ?? 1, 0)
        let available = CGFloat(pixelSize) * (1 - padding * 2)
        let aspect = min(CGFloat(pixelSize) / CGFloat(image.width), CGFloat(pixelSize) / CGFloat(image.height))
        let imageSize = min(available, min(CGFloat(image.width), CGFloat(image.height)) * aspect) * scale
        let drawSize = min(imageSize, available)
        let drawRect = CGRect(
            x: (CGFloat(pixelSize) - drawSize) / 2,
            y: (CGFloat(pixelSize) - drawSize) / 2,
            width: drawSize,
            height: drawSize
        )

        context.saveGState()
        let radius = min(max(icon.cornerRadius, 0), CGFloat(pixelSize) / 2)
        if radius > 0 {
            context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize), cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.clip()
        }
        context.setAlpha(max(0, min(icon.opacity, 1)))
        context.draw(image, in: drawRect)
        context.restoreGState()
        guard let outputImage = context.makeImage() else {
            throw IconExportError.cannotCreateImageContext
        }
        CGImageDestinationAddImage(destination, outputImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw IconExportError.writeFailed
        }
    }

    private static func drawBackground(for id: String, opacity: Double, in context: CGContext, size: Int) {
        let colors: [CGColor]
        switch id {
        case "2":
            colors = [NSColor.systemPurple.cgColor, NSColor.systemIndigo.cgColor]
        case "3":
            colors = [NSColor.systemOrange.cgColor, NSColor.systemPink.cgColor]
        default:
            colors = [NSColor.systemBlue.cgColor, NSColor.systemTeal.cgColor]
        }
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: [0, 1]) else {
            return
        }
        context.saveGState()
        context.setAlpha(max(0, min(opacity, 1)))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size),
            end: CGPoint(x: size, y: 0),
            options: []
        )
        context.restoreGState()
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
