import Foundation
import MagicKit
import OSLog
import SwiftUI

/**
 Banner模板仓库
 代理到BannerTemplateRegistry，提供统一的模板管理接口
 */
final class BannerTemplateRepo: SuperLog, @unchecked Sendable {
    static let shared = BannerTemplateRepo()
    nonisolated static let emoji = "📋"

    private let registry = BannerTemplateRegistry.shared

    private init() {}

    /// 获取所有可用模板
    func getAllTemplates() -> [any BannerTemplateProtocol] {
        return registry.getAllTemplates()
    }

    /// 根据ID获取模板
    func getTemplate(by id: String) -> (any BannerTemplateProtocol)? {
        return registry.getTemplate(by: id)
    }

    /// 获取默认模板
    func getDefaultTemplate() -> any BannerTemplateProtocol {
        return registry.getDefaultTemplate()
    }

    /// 添加新模板（为将来扩展预留）
    func addTemplate(_ template: any BannerTemplateProtocol) {
        os_log(.info, "\(Self.emoji) 添加新模板: \(template.name)")
        registry.register(template)
    }
}
