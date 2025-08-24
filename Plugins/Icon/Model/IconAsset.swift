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
    private let source: IconSource
    
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
    
    /// 异步获取图标图片（支持远程图标加载）
    /// - Returns: 加载完成的SwiftUI Image
    @MainActor
    func getImageAsync() async -> Image {
        switch source {
        case .local:
            return loadImage()
        case .remote:
            return await loadRemoteImage()
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
    
    /// 异步加载远程图标
    /// - Returns: 加载完成的SwiftUI Image
    @MainActor
    private func loadRemoteImage() async -> Image {
        guard let remotePath = remotePath else {
            return Image(systemName: "exclamationmark.triangle")
        }
        
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
            
            return Image(nsImage: nsImage)
        } catch {
            print("加载远程图标失败: \(error)")
            return Image(systemName: "exclamationmark.triangle")
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
