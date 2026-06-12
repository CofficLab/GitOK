import AppKit
import Foundation

enum BannerImageLoadingRules {
    static let maxPreviewImageBytes = 20 * 1024 * 1024

    static func previewImage(at url: URL) -> NSImage? {
        guard imageFileSize(at: url) <= maxPreviewImageBytes else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    private static func imageFileSize(at url: URL) -> Int {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
        return values?.fileSize ?? values?.totalFileAllocatedSize ?? 0
    }
}
