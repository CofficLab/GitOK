import GitCoreKit
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
        Button {
            isSheetPresented.toggle()
        } label: {
            Image(systemName: isAutoPushEnabled ? "arrow.up.circle.fill" : "arrow.up.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isAutoPushEnabled ? .green : .secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isAutoPushEnabled ? PluginAutoPushLocalization.string("Auto-push is enabled - Click to manage") : PluginAutoPushLocalization.string("Auto-push is disabled - Click to configure"))
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
