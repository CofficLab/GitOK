import Foundation
import GitOKSupportKit

enum BannerImageFileOperations {
    static func saveImportedImage(_ url: URL, projectURL: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let ext = url.pathExtension
            let bannerRootURL = projectURL.appendingPathComponent(BannerRepo.bannerStoragePath)
            let imagesFolder = bannerRootURL.appendingPathComponent("images")
            let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: storeURL)
            return storeURL.relativePath.replacingOccurrences(of: projectURL.path, with: "")
        }.value
    }
}
