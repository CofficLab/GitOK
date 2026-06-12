import GitOKAppCore
import GitOKUI
import GitOKSupportKit
import SwiftUI

/// 显示当前项目信息的视图组件
public struct ProjectInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "📁"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    public var body: some View {
        AppSettingSection(title: "当前项目", titleAlignment: .leading) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: project.title,
                    description: project.path,
                    icon: .iconFolder
                ) {
                    AppIconButton(systemImage: "folder", size: .regular) {
                        project.url.openFolder()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

