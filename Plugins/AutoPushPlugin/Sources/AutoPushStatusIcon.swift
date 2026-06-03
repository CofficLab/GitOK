import GitOKCoreKit
import SwiftUI

public struct AutoPushStatusIcon: View {
    let projectPath: String?
    let projectTitle: String?
    let branchName: String?
    let isGitRepository: Bool

    @ObservedObject private var settingsStore = AutoPushSettingsStore.shared
    @ObservedObject private var service = AutoPushService.shared

    @State private var isSheetPresented = false
    @State private var isAutoPushEnabled = false

    public init(projectPath: String?, projectTitle: String?, branchName: String?, isGitRepository: Bool) {
        self.projectPath = projectPath
        self.projectTitle = projectTitle
        self.branchName = branchName
        self.isGitRepository = isGitRepository
    }

    public var body: some View {
        AppStatusBarTile(
            systemImage: isAutoPushEnabled ? "arrow.up.circle.fill" : "arrow.up.circle",
            tint: isAutoPushEnabled ? .green : .secondary,
            action: {
                isSheetPresented.toggle()
            }
        )
        .help(isAutoPushEnabled ? AutoPushPluginLocalization.string("Auto-push is enabled - Click to manage") : AutoPushPluginLocalization.string("Auto-push is disabled - Click to configure"))
        .sheet(isPresented: $isSheetPresented) {
            AutoPushConfigView(projectPath: projectPath, projectTitle: projectTitle, branchName: branchName, isGitRepository: isGitRepository)
                .frame(minWidth: 500, minHeight: 400)
        }
        .onAppear {
            registerService()
            updateStatus()
        }
        .onChange(of: projectPath) { updateStatus() }
        .onChange(of: branchName) { updateStatus() }
        .onChange(of: settingsStore.settings) { updateStatus() }
    }

    private func registerService() {
        service.register {
            guard let projectPath, let projectTitle else { return nil }
            return AutoPushProjectSnapshot(
                projectPath: projectPath,
                projectTitle: projectTitle,
                branchName: branchName,
                isGitRepository: isGitRepository
            )
        }
    }

    private func updateStatus() {
        guard let projectPath, let branchName, isGitRepository else {
            isAutoPushEnabled = false
            return
        }

        isAutoPushEnabled = settingsStore.isAutoPushEnabled(for: projectPath, branchName: branchName)
    }
}
