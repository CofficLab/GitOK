import SwiftUI

public struct CommitUserConfigMenuView<SettingsContent: View>: View {
    private let currentUser: String
    private let currentEmail: String
    private let presets: [CommitUserPreset]
    @Binding private var showUserConfig: Bool
    private let onSelectPreset: (CommitUserPreset) -> Void
    private let onAppear: () -> Void
    private let onUserConfigDidUpdate: () -> Void
    private let onSettingsDisappear: () -> Void
    private let settingsContent: () -> SettingsContent

    public init(
        currentUser: String,
        currentEmail: String,
        presets: [CommitUserPreset],
        showUserConfig: Binding<Bool>,
        onSelectPreset: @escaping (CommitUserPreset) -> Void,
        onAppear: @escaping () -> Void,
        onUserConfigDidUpdate: @escaping () -> Void,
        onSettingsDisappear: @escaping () -> Void,
        @ViewBuilder settingsContent: @escaping () -> SettingsContent
    ) {
        self.currentUser = currentUser
        self.currentEmail = currentEmail
        self.presets = presets
        _showUserConfig = showUserConfig
        self.onSelectPreset = onSelectPreset
        self.onAppear = onAppear
        self.onUserConfigDidUpdate = onUserConfigDidUpdate
        self.onSettingsDisappear = onSettingsDisappear
        self.settingsContent = settingsContent
    }

    public var body: some View {
        CommitUserMenu(
            currentUser: currentUser,
            currentEmail: currentEmail,
            presets: presets,
            onSelectPreset: onSelectPreset,
            onManagePresets: {
                showUserConfig = true
            }
        )
        .sheet(isPresented: $showUserConfig) {
            settingsContent()
                .onDisappear(perform: onSettingsDisappear)
        }
        .onAppear(perform: onAppear)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateGitUserConfigFromCommitPackage)) { _ in
            onUserConfigDidUpdate()
        }
    }
}
