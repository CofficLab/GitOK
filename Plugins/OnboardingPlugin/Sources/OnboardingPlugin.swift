import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum OnboardingPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OnboardingPlugin",
        displayName: OnboardingPluginLocalization.string("OnboardingPlugin"),
        description: OnboardingPluginLocalization.string("Empty-state and onboarding guides"),
        iconName: "questionmark.circle",
        order: 2,
        policy: .alwaysOn,
        tableName: OnboardingPluginLocalization.table
    )

    @MainActor
    public static func onboardingPaneItems(context: GitOKPluginContext) -> [GitOKOnboardingPaneItem] {
        [
            GitOKOnboardingPaneItem(
                id: "\(metadata.id).emptyProjects",
                kind: .emptyProjects,
                view: AnyView(NoRepositoriesGuideView())
            ),
            GitOKOnboardingPaneItem(
                id: "\(metadata.id).projectNotFound",
                kind: .projectNotFound,
                view: AnyView(
                    GuideView(
                        systemImage: "folder.badge.questionmark",
                        title: OnboardingPluginLocalization.string("项目不存在")
                    ).setIconColor(.red.opacity(0.5))
                )
            ),
            GitOKOnboardingPaneItem(
                id: "\(metadata.id).missingDetail",
                kind: .missingDetail,
                view: AnyView(MissingDetailGuideView(onOpenPluginSettings: {
                    context.resolve(GitOKNavigationServicing.self)?.openPluginSettings()
                }))
            ),
        ]
    }
}

public enum OnboardingPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}

struct MissingDetailGuideView: View {
    let onOpenPluginSettings: () -> Void

    var body: some View {
        GuideView(
            systemImage: "puzzlepiece.extension",
            title: OnboardingPluginLocalization.string("暂无可用视图"),
            subtitle: OnboardingPluginLocalization.string("请在设置中启用相关插件以显示内容"),
            action: onOpenPluginSettings,
            actionLabel: OnboardingPluginLocalization.string("打开插件设置")
        )
        .setIconColor(.secondary)
    }
}
