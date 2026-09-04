#if os(macOS)
import AppKit
#endif
import LumiUI
import ProviderCloneRepository
import ProviderProjects
import SwiftUI

/// 无项目时的全屏引导视图。
///
/// 当 `ProjectProviding.projects` 为空时由 RootViewPlugin 通过 overlay
/// 展示在根视图最上层，引导用户添加或克隆仓库。
@MainActor
struct NoProjectGuideView: View {
    let projects: any ProjectProviding
    let cloneProvider: (any CloneRepositoryProviding)?

    @State private var isPresentingClone = false

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
                    Text("Welcome to GitOK", bundle: .module)
                        .font(.appTitle)
                        .foregroundStyle(theme.textPrimary)

                    Text("Add an existing Git repository, or clone a new one to get started.", bundle: .module)
                        .font(.appBody)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                VStack(spacing: DesignTokens.Spacing.md) {
                    AppButton(
                        LocalizedStringKey("Add Project"),
                        systemImage: "folder",
                        style: .primary,
                        size: .medium
                    ) {
                        addExistingProject()
                    }

                    if cloneProvider != nil {
                        AppButton(
                            LocalizedStringKey("Clone Repository"),
                            systemImage: "arrow.triangle.branch",
                            style: .secondary,
                            size: .medium
                        ) {
                            isPresentingClone = true
                        }
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
        #if os(macOS)
        .sheet(isPresented: $isPresentingClone) {
            if let cloneProvider {
                cloneProvider.makeCloneSheetView()
            }
        }
        #endif
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
        panel.prompt = String(localized: "Add", bundle: .module)
        panel.message = String(localized: "Choose a Git repository folder to add to GitOK", bundle: .module)
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
        }
        #endif
    }
}
