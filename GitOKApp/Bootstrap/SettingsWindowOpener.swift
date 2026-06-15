import AppKit
import GitOKAppCore
import SwiftUI

struct SettingsWindowOpener: ViewModifier {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var appVM: AppVM

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                presentSettingsWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openPluginSettings)) { _ in
                appVM.defaultSettingTab = "plugins"
                presentSettingsWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRepositorySettings)) { _ in
                appVM.defaultSettingTab = "repository"
                presentSettingsWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openCommitStyleSettings)) { _ in
                appVM.defaultSettingTab = "commitStyle"
                presentSettingsWindow()
            }
    }

    private func presentSettingsWindow() {
        openWindow(id: AppBootstrap.settingsWindowID)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

extension View {
    func settingsWindowOpener(appVM: AppVM) -> some View {
        modifier(SettingsWindowOpener(appVM: appVM))
    }
}
