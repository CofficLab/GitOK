import SwiftUI

public enum CommitUserConfigHostLogEvent {
    case configLoadSuccess(count: Int)
    case configLoadFailure(Error)
    case applySuccess(name: String, email: String)
    case applyFailure(Error)
}

public struct CommitUserConfigHostView<Project, Config, ConfigID, SettingsContent: View>: View where ConfigID: CustomStringConvertible {
    private let project: Project?
    private let recentConfigLimit: Int
    private let configID: (Config) -> ConfigID
    private let configName: (Config) -> String
    private let configEmail: (Config) -> String
    private let loadProjectUserName: (Project) throws -> String?
    private let loadProjectUserEmail: (Project) throws -> String?
    private let loadRecentConfigs: (Int) throws -> [Config]
    private let applyProjectConfig: (Project, CommitUserConfigRules.Identity) async throws -> Void
    private let logEvent: (CommitUserConfigHostLogEvent) -> Void
    private let settingsContent: () -> SettingsContent

    @State private var currentUser = ""
    @State private var currentEmail = ""
    @State private var showUserConfig = false
    @State private var savedConfigs: [Config] = []

    public init(
        project: Project?,
        recentConfigLimit: Int = CommitUserPreset.recentConfigLimit,
        configID: @escaping (Config) -> ConfigID,
        configName: @escaping (Config) -> String,
        configEmail: @escaping (Config) -> String,
        loadProjectUserName: @escaping (Project) throws -> String?,
        loadProjectUserEmail: @escaping (Project) throws -> String?,
        loadRecentConfigs: @escaping (Int) throws -> [Config],
        applyProjectConfig: @escaping (Project, CommitUserConfigRules.Identity) async throws -> Void,
        logEvent: @escaping (CommitUserConfigHostLogEvent) -> Void = { _ in },
        @ViewBuilder settingsContent: @escaping () -> SettingsContent
    ) {
        self.project = project
        self.recentConfigLimit = recentConfigLimit
        self.configID = configID
        self.configName = configName
        self.configEmail = configEmail
        self.loadProjectUserName = loadProjectUserName
        self.loadProjectUserEmail = loadProjectUserEmail
        self.loadRecentConfigs = loadRecentConfigs
        self.applyProjectConfig = applyProjectConfig
        self.logEvent = logEvent
        self.settingsContent = settingsContent
    }

    public var body: some View {
        CommitUserConfigMenuView(
            currentUser: currentUser,
            currentEmail: currentEmail,
            presets: savedConfigPresentationState.presets,
            showUserConfig: $showUserConfig,
            onSelectPreset: applyPreset,
            onAppear: onAppear,
            onUserConfigDidUpdate: loadUserInfo,
            onSettingsDisappear: {
                CommitUserConfigRules.performSettingsDisappear(
                    loadUserInfo: loadUserInfo,
                    loadSavedConfigs: loadSavedConfigs
                )
            },
            settingsContent: settingsContent
        )
    }

    private var savedConfigCandidates: [CommitUserConfigRules.ConfigCandidate] {
        savedConfigPresentationState.candidates
    }

    private var savedConfigPresentationState: CommitUserConfigRules.SavedConfigPresentationState {
        CommitUserConfigRules.savedConfigPresentationState(configs: savedConfigs.map {
            (id: configID($0), name: configName($0), email: configEmail($0))
        })
    }
}

private extension CommitUserConfigHostView {
    func onAppear() {
        CommitUserConfigRules.performUserViewAppear(
            loadInitialState: loadInitialUserViewState
        )
    }

    func loadInitialUserViewState() {
        CommitUserConfigRules.performInitialUserViewLoad(
            project: project,
            limit: recentConfigLimit,
            loadName: loadProjectUserName,
            loadEmail: loadProjectUserEmail,
            applyIdentity: applyIdentity,
            loadConfigs: loadRecentConfigs,
            applyConfigs: { savedConfigs = $0 },
            logConfigSuccess: { logEvent(.configLoadSuccess(count: $0)) },
            logConfigFailure: { logEvent(.configLoadFailure($0)) }
        )
    }

    func loadUserInfo() {
        CommitUserConfigRules.performProjectIdentityLoad(
            project: project,
            loadName: loadProjectUserName,
            loadEmail: loadProjectUserEmail,
            applyIdentity: applyIdentity
        )
    }

    func applyIdentity(_ identity: CommitUserConfigRules.Identity) {
        CommitUserConfigRules.performIdentity(
            identity,
            setName: { currentUser = $0 },
            setEmail: { currentEmail = $0 }
        )
    }

    func loadSavedConfigs() {
        CommitUserConfigRules.performSavedConfigsLoad(
            limit: recentConfigLimit,
            loadConfigs: loadRecentConfigs,
            applyConfigs: { savedConfigs = $0 },
            logSuccess: { logEvent(.configLoadSuccess(count: $0)) },
            logFailure: { logEvent(.configLoadFailure($0)) }
        )
    }

    func applyConfig(_ config: Config) {
        CommitUserConfigRules.performRequiredProjectApplyConfigCommand(
            project: project,
            currentName: currentUser,
            currentEmail: currentEmail,
            config: config,
            candidateName: configName,
            candidateEmail: configEmail,
            perform: applyConfig
        )
    }

    func applyConfig(_ command: CommitUserConfigRules.ProjectApplyConfigRequest<Project>) {
        // Extract project value before Task to avoid Sendable crossing
        nonisolated(unsafe) let project = command.project

        Task(priority: .userInitiated) { @MainActor in
            let configName = command.request.name
            let configEmail = command.request.email

            guard command.request.state.shouldApply else {
                return
            }

            do {
                let identity = CommitUserConfigRules.identity(name: configName, email: configEmail)
                try await applyProjectConfig(project, identity)
                CommitUserConfigRules.performApplyConfigState(
                    CommitUserConfigRules.applyConfigSuccessState(name: identity.name, email: identity.email),
                    setName: { currentUser = $0 },
                    setEmail: { currentEmail = $0 },
                    postUpdateNotification: {
                        CommitUserConfigRules.postDidUpdateGitUserConfigNotification()
                    }
                )
                logEvent(.applySuccess(name: configName, email: configEmail))
            } catch {
                logEvent(.applyFailure(error))
            }
        }
    }

    func applyPreset(_ preset: CommitUserPreset) {
        CommitUserConfigRules.performMatchingPreset(
            preset,
            candidates: savedConfigCandidates,
            in: savedConfigs,
            id: configID,
            perform: applyConfig
        )
    }
}
