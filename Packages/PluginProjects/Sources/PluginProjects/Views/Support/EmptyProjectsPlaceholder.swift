import AppKit
import LumiUI
import SwiftUI

/// 侧边栏暂无项目时的占位视图（对齐旧版 Onboarding 空态引导）。
struct EmptyProjectsPlaceholder: View {
    let projects: any ProjectSidebarCapability

    @LumiTheme private var theme

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 24)
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text(pluginLocalization.string("Get Started with GitOK"))
                    .font(.callout.weight(.semibold))
                Text(pluginLocalization.string("Add an existing repository, or clone a new one."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 170)
            }
            AppButton(
                pluginLocalization.string("Add Project"),
                systemImage: "folder",
                style: .primary,
                size: .small
            ) {
                addExistingProject()
            }
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addExistingProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = pluginLocalization.string("Add")
        panel.message = pluginLocalization.string("Choose a repository folder to add to GitOK")
        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(at: url)
            projects.openProject(at: url)
        }
    }
}
