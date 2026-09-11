#if os(macOS)
import AppKit
#endif
import LumiUI
import ProviderProjects
import SwiftUI

/// 无项目时的全屏引导视图。
///
/// 当根工作区没有当前项目时显示在工作区区域，引导用户添加或克隆仓库。
@MainActor
struct NoProjectGuideView: View {
    let projects: any ProjectProviding

    @LumiTheme private var theme

    var body: some View {
        ZStack {
            // 半透明遮罩，覆盖在根视图上方但允许底层内容隐约可见。
            theme.background.opacity(0.92)

            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(theme.primary)
                    .scaledToFit()
                    .frame(maxHeight: 80)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(LumiPluginLocalization.string("Welcome to GitOK", bundle: .module))
                        .font(.appTitle)
                        .foregroundStyle(theme.textPrimary)

                    Text(LumiPluginLocalization.string("Add an existing Git repository, or clone a new one to get started.", bundle: .module))
                        .font(.appBody)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                VStack(spacing: DesignTokens.Spacing.md) {
                    AppButton(
                        LumiPluginLocalization.string("Add Project", bundle: .module),
                        systemImage: "folder",
                        style: .primary,
                        size: .medium
                    ) {
                        addExistingProject()
                    }

                }
                .padding(.top, DesignTokens.Spacing.sm)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            backgroundGradient
        }
    }

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                theme.primary.opacity(0.08),
                theme.primary.opacity(0.02),
                theme.background.opacity(0),
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
        .ignoresSafeArea()
    }

    private func addExistingProject() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = LumiPluginLocalization.string("Add", bundle: .module)
        panel.message = LumiPluginLocalization.string("Choose a Git repository folder to add to GitOK", bundle: .module)
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
        }
        #endif
    }
}
