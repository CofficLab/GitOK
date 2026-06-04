import SwiftUI

public enum CommitUserConfigHostLogEvent {
    case configLoadSuccess(count: Int)
    case configLoadFailure(Error)
    case applySuccess(name: String, email: String)
    case applyFailure(Error)
}

private enum CommitUserConfigBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

public struct CommitUserConfigHostView<Project, Config, ConfigID, SettingsContent: View>: View where ConfigID: CustomStringConvertible {
    private let project: Project?
    private let recentConfigLimit: Int
    private let configID: (Config) -> ConfigID
    private let configName: (Config) -> String
    private let configEmail: (Config) -> String
    private let loadProjectUserName: (Project) async throws -> String?
    private let loadProjectUserEmail: (Project) async throws -> String?
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
        loadProjectUserName: @escaping (Project) async throws -> String?,
        loadProjectUserEmail: @escaping (Project) async throws -> String?,
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
        loadUserInfo()
        loadSavedConfigs()
    }

    func loadUserInfo() {
        guard let loadedProject = project else {
            applyIdentity(CommitUserConfigRules.identity(name: nil, email: nil))
            return
        }
        let projectTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let loadProjectUserNameTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: loadProjectUserName)
        let loadProjectUserEmailTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: loadProjectUserEmail)

        Task.detached(priority: .utility) {
            let identity: CommitUserConfigRules.Identity
            do {
                let name = try await loadProjectUserNameTransfer.value(projectTransfer.value)
                let email = try await loadProjectUserEmailTransfer.value(projectTransfer.value)
                identity = CommitUserConfigRules.identity(name: name, email: email)
            } catch {
                identity = CommitUserConfigRules.identity(name: nil, email: nil)
            }

            Task { @MainActor in
                applyIdentity(identity)
            }
        }
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
        let projectTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: command.project)
        let applyProjectConfigTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: applyProjectConfig)
        let logEventTransfer = CommitUserConfigBackgroundRunner.UnsafeTransfer(value: logEvent)
        let configName = command.request.name
        let configEmail = command.request.email
        let shouldApply = command.request.state.shouldApply

        Task.detached(priority: .userInitiated) {
            guard shouldApply else {
                return
            }

            do {
                let identity = CommitUserConfigRules.identity(name: configName, email: configEmail)
                try await applyProjectConfigTransfer.value(projectTransfer.value, identity)

                Task { @MainActor in
                    CommitUserConfigRules.performApplyConfigState(
                        CommitUserConfigRules.applyConfigSuccessState(name: identity.name, email: identity.email),
                        setName: { currentUser = $0 },
                        setEmail: { currentEmail = $0 },
                        postUpdateNotification: {
                            CommitUserConfigRules.postDidUpdateGitUserConfigNotification()
                        }
                    )
                    logEventTransfer.value(.applySuccess(name: configName, email: configEmail))
                }
            } catch {
                Task { @MainActor in
                    logEventTransfer.value(.applyFailure(error))
                }
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
