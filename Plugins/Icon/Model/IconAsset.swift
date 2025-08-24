import Foundation
import SwiftUI
import Cocoa
import MagicCore

/**
 * 图标来源类型
 */
enum IconSource {
    case local
    case remote
}

/**
 * 图标资源工具类
 * 负责处理IconCategory下的具体图标操作
 * 支持多种文件格式（PNG、SVG等），自动检测和智能查找
 * 同时支持本地和远程图标的统一管理
 */
class IconAsset: Identifiable {
    /// 图标来源类型
    let source: IconSource
    
    /// 图标文件URL（本地图标）或远程路径（远程图标）
    let fileURL: URL?
    let remotePath: String?
    
    /// 稳定的ID
    var id: String { 
        switch source {
        case .local:
            return fileURL?.path ?? ""
        case .remote:
            return remotePath ?? ""
        }
    }
    
    /// 图标所属分类名称
    var categoryName: String {
        switch source {
        case .local:
            return fileURL?.deletingLastPathComponent().lastPathComponent ?? ""
        case .remote:
            return remotePath?.components(separatedBy: "/").first ?? ""
        }
    }
    
    /// 图标ID
    var iconId: String {
        switch source {
        case .local:
            return fileURL?.deletingPathExtension().lastPathComponent ?? ""
        case .remote:
            return remotePath?.components(separatedBy: "/").last?.replacingOccurrences(of: ".svg", with: "") ?? ""
        }
    }
    
    /// 本地图标初始化方法
    /// - Parameter fileURL: 图标文件URL
    init(fileURL: URL) {
        self.source = .local
        self.fileURL = fileURL
        self.remotePath = nil
    }
    
    /// 远程图标初始化方法
    /// - Parameter remotePath: 远程图标路径
    init(remotePath: String) {
        self.source = .remote
        self.fileURL = nil
        self.remotePath = remotePath
    }
    
    /// 获取图标图片
    /// - Returns: SwiftUI Image
    func getImage() -> Image {
        switch source {
        case .local:
            return loadImage()
        case .remote:
            // 对于远程图标，返回一个占位符图片
            // 实际的图片加载将在UI层面异步处理
            return Image(systemName: "photo")
        }
    }
    
    /// 获取可调整大小的图标视图
    /// - Parameter size: 图标大小
    /// - Returns: 图标视图，已设置大小
    func getResizableIconView(size: CGFloat) -> some View {
        switch source {
        case .local:
            return AnyView(
                loadImage()
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            )
        case .remote:
            return AnyView(
                RemoteIconView(iconAsset: self)
                    .frame(width: size, height: size)
            )
        }
    }
    
    /// 检查图标文件是否存在
    /// - Returns: 是否存在
    func exists() -> Bool {
        switch source {
        case .local:
            return fileURL != nil && FileManager.default.fileExists(atPath: fileURL!.path)
        case .remote:
            return remotePath != nil
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
        guard let fileURL = fileURL else {
            return Image(systemName: "doc.text.image")
        }
        
        // macOS原生支持SVG格式，可以直接使用NSImage加载
        if let nsImage = NSImage(contentsOf: fileURL) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "doc.text.image")
        }
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
    
    /// 加载本地缩略图（支持多种格式）
    /// - Returns: SwiftUI Image
    private func loadLocalThumbnail() -> Image {
        guard let fileURL = fileURL else {
            return Image(systemName: "plus")
        }
        
        let fileExtension = fileURL.pathExtension.lowercased()
        
        switch fileExtension {
        case "svg":
            // SVG缩略图可以直接使用原图，因为它是矢量图形
            return loadSVGImage()
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterThumbnail()
        default:
            return Image(systemName: "plus")
        }
    }
    
    /// 加载光栅图片缩略图
    /// - Returns: SwiftUI Image
    private func loadRasterThumbnail() -> Image {
        guard let fileURL = fileURL else {
            return Image(systemName: "plus")
        }
        
        if let image = NSImage(contentsOf: fileURL) {
            if let thumbnail = generateThumbnail(for: image) {
                return Image(nsImage: thumbnail)
            } else {
                return Image(systemName: "plus")
            }
        } else {
            return Image(systemName: "plus")
        }
    }
    
    /// 生成缩略图
    /// - Parameter image: 原始图片
    /// - Returns: 缩略图
    private func generateThumbnail(for image: NSImage) -> NSImage? {
        let thumbnailSize = NSSize(width: 50, height: 50)
        
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 加载远程缩略图
    /// - Returns: SwiftUI Image
    private func loadRemoteThumbnail() -> Image {
        // 对于远程图标，返回一个占位符图片
        // 实际的远程图片加载将在UI层面异步处理
        return Image(systemName: "photo")
    }
}


// MARK: - 统一图标结构体

/**
 * 统一图标
 * 整合本地和远程图标数据
 */
struct UnifiedIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let source: IconSource
    let localIcon: IconAsset?
    let remoteIcon: RemoteIcon?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UnifiedIcon, rhs: UnifiedIcon) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 远程图标相关结构体

/**
 * 远程图标
 * 对应网络API返回的图标数据结构
 */
struct RemoteIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIcon, rhs: RemoteIcon) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 远程图标分类
 * 对应网络API返回的分类数据结构
 */
struct RemoteIconCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let iconCount: Int
    let remoteIconIds: [RemoteIconData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIconCategory, rhs: RemoteIconCategory) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 图标清单数据结构
 * 对应API返回的JSON数据结构
 */
struct IconManifest: Codable {
    let generatedAt: String
    let totalIcons: Int
    let totalCategories: Int
    let categories: [CategoryData]
    let iconsByCategory: [String: [RemoteIconData]]
    
    enum CodingKeys: String, CodingKey {
        case generatedAt
        case totalIcons
        case totalCategories
        case categories
        case iconsByCategory
    }
}

/**
 * 分类数据结构
 * 对应API返回的分类数据
 */
struct CategoryData: Codable {
    let id: String
    let name: String
    let count: Int
}

/**
 * 远程图标数据结构
 * 对应API返回的图标数据
 */
struct RemoteIconData: Codable {
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
}

// MARK: - 错误类型

/**
 * 远程图标仓库错误类型
 */
enum RemoteIconError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError:
            return "网络请求失败"
        case .decodingError:
            return "数据解析失败"
        }
    }
}

// MARK: - 远程图标视图组件

/**
 * 远程图标视图组件
 * 负责异步加载和显示远程图标
 */
struct RemoteIconView: View {
    let iconAsset: IconAsset
    @State private var loadedImage: Image?
    @State private var isLoading = false
    @State private var hasError = false
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                // 显示已加载的图片
                loadedImage
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                // 显示加载状态
                ProgressView()
                    .frame(width: 50, height: 50)
            } else if hasError {
                // 显示错误状态
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.orange)
            } else {
                // 显示默认占位符
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadRemoteImage()
        }
    }
    
    private func loadRemoteImage() {
        guard iconAsset.source == .remote,
              let remotePath = iconAsset.remotePath else {
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            await performRemoteImageLoad(remotePath: remotePath)
        }
    }
    
    @MainActor
    private func performRemoteImageLoad(remotePath: String) async {
        do {
            // 使用WebIconRepo获取远程图标的URL
            guard let iconURL = WebIconRepo.shared.getIconURL(for: remotePath) else {
                throw RemoteIconError.invalidURL
            }
            
            // 异步加载远程图片
            let (data, response) = try await URLSession.shared.data(from: iconURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw RemoteIconError.networkError
            }
            
            // 将数据转换为NSImage，然后转换为SwiftUI Image
            guard let nsImage = NSImage(data: data) else {
                throw RemoteIconError.decodingError
            }
            
            loadedImage = Image(nsImage: nsImage)
            isLoading = false
        } catch {
            hasError = true
            isLoading = false
            print("加载远程图标失败: \(error)")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .frame(width: 1200)
            .frame(height: 1200)
    }
}
