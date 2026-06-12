import AppKit
import Foundation

enum IconImageLoadingRules {
    static let maxPreviewImageBytes = 10 * 1024 * 1024

    static func canLoadImageData(at url: URL) -> Bool {
        imageFileSize(at: url) <= maxPreviewImageBytes
    }

    static func localImage(at url: URL) -> NSImage? {
        guard canLoadImageData(at: url) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    static func decodedImage(from data: Data) -> NSImage? {
        guard data.count <= maxPreviewImageBytes else {
            return nil
        }

        return NSImage(data: data)
    }

    private static func imageFileSize(at url: URL) -> Int {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
        return values?.fileSize ?? values?.totalFileAllocatedSize ?? 0
    }
}
