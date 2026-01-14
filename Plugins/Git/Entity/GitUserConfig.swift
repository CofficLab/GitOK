import Foundation
import SwiftData
import SwiftUI

/// Git 用户配置模型
/// 存储用户的 Git 姓名和邮箱信息
@Model
final class GitUserConfig: SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 用户姓名
    var name: String

    /// 用户邮箱
    var email: String

    /// 创建时间戳
    var timestamp: Date

    /// 是否为默认配置
    var isDefault: Bool
    
    var title: String {
        name.isEmpty ? email : name
    }
    
    init(name: String, email: String, isDefault: Bool = false) {
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.timestamp = .now
    }
}

extension GitUserConfig: Identifiable {
    var id: String {
        "\(name)_\(email)"
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
