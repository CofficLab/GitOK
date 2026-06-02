import GitOKFoundationKit
import GitOKDesignKit
import Foundation
import OSLog
import SwiftUI

extension URL {
    /// 从音频文件的元数据中获取封面图片
    /// - Parameters:
    ///   - size: 可选参数，指定返回图片的大小。如果为 nil，则返回原始大小
    ///   - verbose: 是否输出详细日志
    /// - Returns: 如果找到封面则返回 SwiftUI.Image，否则返回 nil
    public func coverFromMetadata(
        size: CGSize? = nil,
        verbose: Bool = false
    ) async throws -> Image? {
        if let platformImage = try await extractCoverFromMetadata(verbose: verbose) {
            if let size = size {
                return platformImage.resize(to: size).toSwiftUIImage()
            }
            return platformImage.toSwiftUIImage()
        }
        return nil
    }

    /// 获取文件的缩略图
    /// - Parameters:
    ///   - size: 缩略图的目标大小
    ///   - useDefaultIcon: 是否使用默认图标，默认为 true
    ///   - verbose: 是否输出详细日志
    ///   - reason: 调用原因（用于日志）
    /// - Returns: 缩略图结果，包含图片和元数据，如果无法生成则返回 nil
    public func thumbnail(
        size: CGSize = CGSize(width: 120, height: 120),
        useDefaultIcon: Bool = true,
        verbose: Bool,
        reason: String
    ) async throws -> ThumbnailResult? {
        let canUseCache = isDownloaded || isNotiCloud

        // 检查缓存
        if canUseCache, let cachedImage = ThumbnailCache.shared.fetch(for: self, size: size) {
            if verbose {
                os_log("\(self.t)🐛 (\(reason)) 从缓存中获取缩略图")
            }
            // 从缓存中获取的图片，标记为 cached
            return ThumbnailResult(
                image: cachedImage,
                isSystemIcon: false,  // 缓存中的都是非系统图标
                fileType: self.fileType,
                source: .cached,
                isCached: true
            )
        }

        do {
            // 使用生成器创建缩略图
            let generator = ThumbnailGenerator(
                url: self,
                size: size,
                useDefaultIcon: useDefaultIcon,
                verbose: verbose,
                reason: reason
            )

            let result = try await generator.generate()

            // 只缓存非系统图标的缩略图
            if let result = result, !result.isSystemIcon, let image = result.image {
                let cache = ThumbnailCache.shared
                cache.verbose = verbose
                cache.save(image, for: self, size: size)
                // 更新缓存状态
                return ThumbnailResult(
                    image: image,
                    isSystemIcon: result.isSystemIcon,
                    fileType: result.fileType,
                    source: result.source,
                    isCached: true
                )
            }

            return result
        } catch {
            os_log(.error, "\(self.t)<\(self.title)>获取缩略图失败: \(error.localizedDescription)")
            throw error
        }
    }

    /// 获取文件的缩略图（SwiftUI.Image 格式）
    /// - Parameters:
    ///   - size: 缩略图的目标大小
    ///   - useDefaultIcon: 是否使用默认图标
    ///   - verbose: 是否输出详细日志
    ///   - reason: 调用原因
    /// - Returns: SwiftUI.Image，如果无法生成则返回 nil
    /// - Throws: 缩略图生成过程中的错误
    public func thumbnailImage(
        size: CGSize = CGSize(width: 120, height: 120),
        useDefaultIcon: Bool = true,
        verbose: Bool,
        reason: String
    ) async throws -> Image? {
        guard let result: ThumbnailResult = try await thumbnail(
            size: size,
            useDefaultIcon: useDefaultIcon,
            verbose: verbose,
            reason: reason
        ) else {
            return nil
        }
        return result.toSwiftUIImage()
    }

    /// 获取文件的缩略图（原生图片格式，内部使用）
    /// - Parameters:
    ///   - size: 缩略图的目标大小
    ///   - useDefaultIcon: 是否使用默认图标
    ///   - verbose: 是否输出详细日志
    ///   - reason: 调用原因
    /// - Returns: 生成的缩略图结果
    public func platformThumbnail(
        size: CGSize = CGSize(width: 120, height: 120),
        useDefaultIcon: Bool = true,
        verbose: Bool,
        reason: String
    ) async throws -> ThumbnailResult? {
        let generator = ThumbnailGenerator(
            url: self,
            size: size,
            useDefaultIcon: useDefaultIcon,
            verbose: verbose,
            reason: reason
        )
        return try await generator.generate()
    }

    /// 获取缩略图缓存目录
    /// - Returns: 缩略图缓存目录的 URL
    public static func thumbnailCacheDirectory() -> URL {
        return ThumbnailCache.shared.getCacheDirectory()
    }
}

// MARK: - FileType 辅助方法

private extension URL {
    /// 根据 URL 路径或扩展名推断文件类型
    var fileType: FileType {
        if hasDirectoryPath {
            return .folder
        }
        if isImage {
            return .image
        }
        if isVideo {
            return .video
        }
        if isAudio {
            return .audio
        }
        // 可以根据扩展名添加更多文档类型的判断
        let ext = pathExtension.lowercased()
        if ["pdf", "doc", "docx", "txt", "rtf", "pages"].contains(ext) {
            return .document
        }
        return .unknown
    }
}

// MARK: - Preview

