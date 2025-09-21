import Cocoa
import Foundation
import MagicCore
import MagicHTTP
import SwiftUI

/**
 * 图标来源类型
 */
enum IconSource {
    case local
    case remote
    case generated
}

/**
 * 图标资源工具类
 * 负责处理IconCategory下的具体图标操作
 * 支持多种文件格式（PNG、SVG等），自动检测和智能查找
 * 同时支持本地和远程图标的统一管理
 */
class IconAsset: Identifiable {
    /// 图标来源类型
    private let source: IconSource

    /// 图标文件URL（本地图标和远程图标统一使用）
    let fileURL: URL?
    /// 生成型视图构造器（用于 MagicAsset 等基于 SwiftUI 的图标）
    let viewBuilder: (() -> AnyView)?
    /// 生成型视图的稳定标识
    private let viewId: String?

    /// 稳定的ID
    var id: String {
        switch source {
        case .local:
            return fileURL?.path ?? ""
        case .remote:
            return fileURL?.absoluteString ?? ""
        case .generated:
            return viewId ?? ""
        }
    }

    /// 图标所属分类名称
    var categoryName: String {
        switch source {
        case .local:
            return fileURL?.deletingLastPathComponent().lastPathComponent ?? ""
        case .remote:
            return fileURL?.pathComponents.dropFirst().first ?? ""
        case .generated:
            return "MagicAsset"
        }
    }

    /// 图标ID
    var iconId: String {
        switch source {
        case .local:
            return fileURL?.deletingPathExtension().lastPathComponent ?? ""
        case .remote:
            let lastComponent = fileURL?.lastPathComponent ?? ""
            return lastComponent.replacingOccurrences(of: ".svg", with: "")
                .replacingOccurrences(of: ".png", with: "")
                .replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".jpeg", with: "")
        case .generated:
            return viewId ?? ""
        }
    }

    /// 本地图标初始化方法
    /// - Parameter fileURL: 图标文件URL
    init(fileURL: URL) {
        self.source = .local
        self.fileURL = fileURL
        self.viewBuilder = nil
        self.viewId = nil
    }

    /// 远程图标初始化方法
    /// - Parameter remoteURL: 远程图标URL
    init(remoteURL: URL) {
        self.source = .remote
        self.fileURL = remoteURL
        self.viewBuilder = nil
        self.viewId = nil
    }

    /// 生成型图标初始化方法（基于 SwiftUI 视图）
    /// - Parameters:
    ///   - viewBuilder: 返回任意 SwiftUI 视图的构造器
    ///   - id: 稳定标识（用于选择/比较）
    init(viewBuilder: @escaping () -> AnyView, id: String) {
        self.source = .generated
        self.fileURL = nil
        self.viewBuilder = viewBuilder
        self.viewId = id
    }

    /// 异步获取图标图片（支持远程图标加载）
    /// - Returns: 加载完成的SwiftUI Image
    @MainActor
    func getImage() async -> Image {
        switch source {
        case .local:
            return loadImage()
        case .remote:
            return await loadRemoteImage()
        case .generated:
            return loadGeneratedImage()
        }
    }

    // MARK: - 私有实例方法

    /// 加载图片（支持多种格式）
    /// - Returns: SwiftUI Image
    private func loadImage() -> Image {
        guard let fileURL = fileURL else {
            return Image(systemName: "plus")
        }

        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "svg":
            return loadSVGImage()
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterImage()
        default:
            return Image(systemName: "plus")
        }
    }

    /// 加载SVG图片
    /// - Returns: SwiftUI Image
    private func loadSVGImage() -> Image {
        guard let fileURL = fileURL, let nsImage = NSImage(contentsOf: fileURL) else {
            return Image.doc
        }

        return Image(nsImage: nsImage)
    }

    /// 加载光栅图片（PNG、JPG等）
    /// - Returns: SwiftUI Image
    private func loadRasterImage() -> Image {
        guard let fileURL = fileURL else {
            return Image(systemName: "plus")
        }

        if let nsImage = NSImage(contentsOf: fileURL) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "plus")
        }
    }

    /// 将生成型视图转为图片
    /// - Returns: SwiftUI Image
    @MainActor
    private func loadGeneratedImage() -> Image {
        guard let viewBuilder = viewBuilder else {
            return Image(systemName: "sparkles")
        }
        // 为了避免缩略图模糊，先以较大的固定尺寸渲染，再缩小显示
        let sizedView = AnyView(viewBuilder().frame(width: 1024, height: 1024))
        return sizedView.toImage()
    }

    /// 异步加载远程图标
    /// - Returns: 加载完成的SwiftUI Image
    @MainActor
    private func loadRemoteImage() async -> Image {
        guard let iconURL = fileURL else {
            return Image(systemName: "exclamationmark.triangle")
        }

        do {
            // 异步加载远程图片
            let (data, _) = try await iconURL.httpGetData(cacheMaxAge: 3600)

            // 将数据转换为NSImage，然后转换为SwiftUI Image
            guard let nsImage = NSImage(data: data) else {
                throw RemoteIconError.decodingError
            }

            return Image(nsImage: nsImage)
        } catch {
            print("加载远程图标失败: \(error)")
            return Image(systemName: "exclamationmark.triangle")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 700)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .frame(width: 1200)
            .frame(height: 1200)
    }
}
