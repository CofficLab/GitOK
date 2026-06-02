import BannerCoreKit
import Foundation
import GitOKCoreKit
import MagicKit
import OSLog
import ProjectRulesKit
import SwiftUI

/**
    Banner数据模型
    纯数据存储结构，负责存储Banner的配置信息
    不包含任何UI渲染逻辑，只负责数据的序列化和反序列化
    类似于IconData的设计模式，遵循单一职责原则
**/
struct BannerFile: SuperLog {
    nonisolated static let emoji = "📄"
    nonisolated static let empty = BannerFile(path: "", projectURL: URL(fileURLWithPath: "/"))

    /// 所属项目
    var projectURL: URL

    /// 可序列化的磁盘记录，和 Project/UI 状态分离。
    var record: BannerRecord = BannerRecord(path: "")

    // MARK: - 初始化方法

    init(
        path: String,
        projectURL: URL,
        templateData: [String: String] = [:],
        lastSelectedTemplateId: String = ""
    ) {
        self.projectURL = projectURL
        self.record = BannerRecord(
            path: path,
            document: BannerDocument(
                templateData: templateData,
                lastSelectedTemplateId: lastSelectedTemplateId
            )
        )
    }

    // MARK: - 业务方法

    /// 保存到磁盘
    /// - Throws: 保存失败时抛出错误
    func saveToDisk() throws {
        try BannerRepo.shared.saveBanner(self)
    }

    /// 保存图片到项目目录
    /// - Parameter url: 图片URL
    /// - Returns: 保存后的图片相对路径
    func saveImage(_ url: URL) throws -> String {
        let ext = url.pathExtension
        let bannerRootURL = projectURL.appendingPathComponent(BannerRepo.bannerStoragePath)
        let imagesFolder = bannerRootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")

        os_log(.info, "\(Self.emoji) 保存图片")
        os_log(.info, "  ➡️ 源: \(url.relativeString)")
        os_log(.info, "  ➡️ 目标: \(storeURL.relativeString)")

        do {
            // 确保图片目录存在
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)

            // 复制图片到新位置
            try FileManager.default.copyItem(at: url, to: storeURL)
            return BannerStorageRules.relativeProjectPath(for: storeURL, projectPath: projectURL.path)
        } catch {
            os_log(.error, "\(Self.emoji) 保存图片失败: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Template Data

extension BannerFile {
    /// 配置文件路径
    var path: String {
        get { record.path }
        set { record.path = newValue }
    }

    /// 可序列化的文档核心
    var document: BannerDocument {
        get { record.document }
        set { record.document = newValue }
    }

    /// 模板特定的数据（JSON格式存储）
    /// key 是模板的 ID，value 是模板的数据
    var templateData: [String: String] {
        get { document.templateData }
        set { document.templateData = newValue }
    }

    /// 最后选择的模板ID
    var lastSelectedTemplateId: String {
        get { document.lastSelectedTemplateId }
        set { document.lastSelectedTemplateId = newValue }
    }

    /// 获取模板数据
    /// - Parameter templateId: 模板ID
    /// - Returns: 模板数据的JSON字符串
    func getTemplateData(_ templateId: String) -> String? {
        document.templateDataValue(for: templateId)
    }

    /// 设置模板数据
    /// - Parameters:
    ///   - templateId: 模板ID
    ///   - data: 模板数据的JSON字符串
    mutating func setTemplateData(_ templateId: String, data: String) throws {
        document.setTemplateDataValue(data, for: templateId)
        try self.saveToDisk()
    }
}

// MARK: - Identifiable

extension BannerFile: Identifiable {
    var id: String {
        record.id
    }
}

// MARK: - Equatable

extension BannerFile: Equatable {
    static func == (lhs: BannerFile, rhs: BannerFile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension BannerFile: Codable {
    init(from decoder: Decoder) throws {
        // 这些值在反序列化时临时设置，实际值由ProjectBannerRepo在加载时设置
        projectURL = URL(fileURLWithPath: "/")
        record = try BannerRecord(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try record.encode(to: encoder)
    }
}
