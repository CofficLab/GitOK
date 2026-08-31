import Foundation

public enum CommitUserConfigRules {
    public struct Identity: Equatable, Sendable {
        public let name: String
        public let email: String

        public init(name: String, email: String) {
            self.name = name
            self.email = email
        }
    }

    public struct ApplyConfigState: Equatable, Sendable {
        public let identity: Identity
        public let postsUpdateNotification: Bool

        public init(identity: Identity, postsUpdateNotification: Bool) {
            self.identity = identity
            self.postsUpdateNotification = postsUpdateNotification
        }
    }

    public struct ConfigCandidate: Equatable, Sendable {
        public let id: String
        public let name: String
        public let email: String

        public init(id: String, name: String, email: String) {
            self.id = id
            self.name = name
            self.email = email
        }
    }

    public struct ApplyConfigRequestState: Equatable, Sendable {
        public let shouldApply: Bool

        public init(shouldApply: Bool) {
            self.shouldApply = shouldApply
        }
    }

    public struct ApplyConfigRequest: Equatable, Sendable {
        public let state: ApplyConfigRequestState
        public let name: String
        public let email: String

        public init(state: ApplyConfigRequestState, name: String, email: String) {
            self.state = state
            self.name = name
            self.email = email
        }
    }

    public struct ProjectApplyConfigRequest<Project> {
        public let request: ApplyConfigRequest
        public let project: Project

        public init(request: ApplyConfigRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct ApplyConfigHandlers {
        public let apply: (Identity) async throws -> Void

        public init(apply: @escaping (Identity) async throws -> Void) {
            self.apply = apply
        }
    }

    public struct ProjectApplyConfigHandlers<Project> {
        public let apply: (Project, Identity) async throws -> Void

        public init(apply: @escaping (Project, Identity) async throws -> Void) {
            self.apply = apply
        }
    }

    public struct SavedConfigPresentationState: Equatable, Sendable {
        public let candidates: [ConfigCandidate]
        public let presets: [CommitUserPreset]

        public init(candidates: [ConfigCandidate], presets: [CommitUserPreset]) {
            self.candidates = candidates
            self.presets = presets
        }
    }

    public static let didUpdateGitUserConfigNotificationName = "didUpdateGitUserConfig"

    public static func savedConfigsLoadedLogMessage(count: Int) -> String {
        "Loaded \(count) saved configs"
    }

    public static func savedConfigsLoadFailureLogMessage(errorDescription: String) -> String {
        "Failed to load saved configs: \(errorDescription)"
    }

    public static func appliedConfigLogMessage(name: String, email: String) -> String {
        "✅ Applied config: \(name) <\(email)>"
    }

    public static func applyConfigFailureLogMessage(errorDescription: String) -> String {
        "❌ Failed to apply config: \(errorDescription)"
    }

    public static func identity(name: String?, email: String?) -> Identity {
        Identity(name: name ?? "", email: email ?? "")
    }

    public static func performIdentity(
        _ identity: Identity,
        setName: (String) -> Void,
        setEmail: (String) -> Void
    ) {
        setName(identity.name)
        setEmail(identity.email)
    }

    public static func performIdentityLoad(
        loadName: () throws -> String?,
        loadEmail: () throws -> String?,
        applyIdentity: (Identity) -> Void
    ) {
        do {
            applyIdentity(identity(name: try loadName(), email: try loadEmail()))
        } catch {
            applyIdentity(identity(name: nil, email: nil))
        }
    }

    public static func performProjectIdentityLoad<Project>(
        project: Project?,
        loadName: (Project) throws -> String?,
        loadEmail: (Project) throws -> String?,
        applyIdentity: (Identity) -> Void
    ) {
        performIdentityLoad(
            loadName: {
                guard let project else { return nil }
                return try loadName(project)
            },
            loadEmail: {
                guard let project else { return nil }
                return try loadEmail(project)
            },
            applyIdentity: applyIdentity
        )
    }

    public static func performSavedConfigsLoad<Config>(
        limit: Int,
        loadConfigs: (Int) throws -> [Config],
        applyConfigs: ([Config]) -> Void,
        logSuccess: (Int) -> Void,
        logFailure: (Error) -> Void
    ) {
        do {
            let configs = try loadConfigs(limit)
            applyConfigs(configs)
            logSuccess(configs.count)
        } catch {
            logFailure(error)
        }
    }

    public static func performInitialUserViewLoad<Config>(
        limit: Int,
        loadName: () throws -> String?,
        loadEmail: () throws -> String?,
        applyIdentity: (Identity) -> Void,
        loadConfigs: (Int) throws -> [Config],
        applyConfigs: ([Config]) -> Void,
        logConfigSuccess: (Int) -> Void,
        logConfigFailure: (Error) -> Void
    ) {
        performIdentityLoad(
            loadName: loadName,
            loadEmail: loadEmail,
            applyIdentity: applyIdentity
        )
        performSavedConfigsLoad(
            limit: limit,
            loadConfigs: loadConfigs,
            applyConfigs: applyConfigs,
            logSuccess: logConfigSuccess,
            logFailure: logConfigFailure
        )
    }

    public static func performInitialUserViewLoad<Project, Config>(
        project: Project?,
        limit: Int,
        loadName: (Project) throws -> String?,
        loadEmail: (Project) throws -> String?,
        applyIdentity: (Identity) -> Void,
        loadConfigs: (Int) throws -> [Config],
        applyConfigs: ([Config]) -> Void,
        logConfigSuccess: (Int) -> Void,
        logConfigFailure: (Error) -> Void
    ) {
        performProjectIdentityLoad(
            project: project,
            loadName: loadName,
            loadEmail: loadEmail,
            applyIdentity: applyIdentity
        )
        performSavedConfigsLoad(
            limit: limit,
            loadConfigs: loadConfigs,
            applyConfigs: applyConfigs,
            logSuccess: logConfigSuccess,
            logFailure: logConfigFailure
        )
    }

    public static func performUserViewAppear(loadInitialState: () -> Void) {
        loadInitialState()
    }

    public static func performSettingsDisappear(
        loadUserInfo: () -> Void,
        loadSavedConfigs: () -> Void
    ) {
        loadUserInfo()
        loadSavedConfigs()
    }

    public static func shouldApplyConfig(
        currentName: String,
        currentEmail: String,
        candidateName: String,
        candidateEmail: String
    ) -> Bool {
        CommitUserPreset.isSameUser(
            currentName: currentName,
            currentEmail: currentEmail,
            candidateName: candidateName,
            candidateEmail: candidateEmail
        ) == false
    }

    public static func applyConfigRequestState(
        currentName: String,
        currentEmail: String,
        candidateName: String,
        candidateEmail: String
    ) -> ApplyConfigRequestState {
        ApplyConfigRequestState(
            shouldApply: shouldApplyConfig(
                currentName: currentName,
                currentEmail: currentEmail,
                candidateName: candidateName,
                candidateEmail: candidateEmail
            )
        )
    }

    public static func performApplyConfigRequestState(
        _ state: ApplyConfigRequestState,
        perform: () -> Void
    ) -> Bool {
        guard state.shouldApply else {
            return false
        }

        perform()
        return true
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        perform: (Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectApplyConfig<Project>(
        project: Project?,
        currentName: String,
        currentEmail: String,
        candidateName: String,
        candidateEmail: String,
        perform: (ApplyConfigRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(
            ApplyConfigRequest(
                state: applyConfigRequestState(
                    currentName: currentName,
                    currentEmail: currentEmail,
                    candidateName: candidateName,
                    candidateEmail: candidateEmail
                ),
                name: candidateName,
                email: candidateEmail
            ),
            project
        )
        return true
    }

    @discardableResult
    public static func performRequiredProjectApplyConfig<Project, Config>(
        project: Project?,
        currentName: String,
        currentEmail: String,
        config: Config,
        candidateName: (Config) -> String,
        candidateEmail: (Config) -> String,
        perform: (ApplyConfigRequest, Project) -> Void
    ) -> Bool {
        performRequiredProjectApplyConfig(
            project: project,
            currentName: currentName,
            currentEmail: currentEmail,
            candidateName: candidateName(config),
            candidateEmail: candidateEmail(config),
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectApplyConfigCommand<Project>(
        project: Project?,
        currentName: String,
        currentEmail: String,
        candidateName: String,
        candidateEmail: String,
        perform: (ProjectApplyConfigRequest<Project>) -> Void
    ) -> Bool {
        performRequiredProjectApplyConfig(
            project: project,
            currentName: currentName,
            currentEmail: currentEmail,
            candidateName: candidateName,
            candidateEmail: candidateEmail
        ) { request, project in
            perform(ProjectApplyConfigRequest(request: request, project: project))
        }
    }

    @discardableResult
    public static func performRequiredProjectApplyConfigCommand<Project, Config>(
        project: Project?,
        currentName: String,
        currentEmail: String,
        config: Config,
        candidateName: (Config) -> String,
        candidateEmail: (Config) -> String,
        perform: (ProjectApplyConfigRequest<Project>) -> Void
    ) -> Bool {
        performRequiredProjectApplyConfigCommand(
            project: project,
            currentName: currentName,
            currentEmail: currentEmail,
            candidateName: candidateName(config),
            candidateEmail: candidateEmail(config),
            perform: perform
        )
    }

    public static func matchingConfigID(
        for preset: CommitUserPreset,
        candidates: [ConfigCandidate]
    ) -> String? {
        candidates.first {
            preset.matchesConfig(id: $0.id, name: $0.name, email: $0.email)
        }?.id
    }

    public static func firstItem<Item, ID>(
        matchingID targetID: String,
        in items: [Item],
        id: (Item) -> ID
    ) -> Item? {
        items.first { String(describing: id($0)) == targetID }
    }

    public static func matchingItem<Item, ID>(
        for preset: CommitUserPreset,
        candidates: [ConfigCandidate],
        in items: [Item],
        id: (Item) -> ID
    ) -> Item? {
        guard let configID = matchingConfigID(for: preset, candidates: candidates) else {
            return nil
        }

        return firstItem(matchingID: configID, in: items, id: id)
    }

    @discardableResult
    public static func performMatchingPreset<Item, ID>(
        _ preset: CommitUserPreset,
        candidates: [ConfigCandidate],
        in items: [Item],
        id: (Item) -> ID,
        perform: (Item) -> Void
    ) -> Bool {
        guard let item = matchingItem(
            for: preset,
            candidates: candidates,
            in: items,
            id: id
        ) else {
            return false
        }

        perform(item)
        return true
    }

    public static func presets(from candidates: [ConfigCandidate]) -> [CommitUserPreset] {
        CommitUserPreset.presets(configs: candidates.map {
            (id: $0.id, name: $0.name, email: $0.email)
        })
    }

    public static func configCandidates<ID>(
        from configs: [(id: ID, name: String, email: String)]
    ) -> [ConfigCandidate] where ID: CustomStringConvertible {
        configs.map {
            ConfigCandidate(
                id: $0.id.description,
                name: $0.name,
                email: $0.email
            )
        }
    }

    public static func savedConfigPresentationState<ID>(
        configs: [(id: ID, name: String, email: String)]
    ) -> SavedConfigPresentationState where ID: CustomStringConvertible {
        let candidates = configCandidates(from: configs)
        return SavedConfigPresentationState(
            candidates: candidates,
            presets: presets(from: candidates)
        )
    }

    public static func applyConfigSuccessState(name: String, email: String) -> ApplyConfigState {
        ApplyConfigState(
            identity: identity(name: name, email: email),
            postsUpdateNotification: true
        )
    }

    public static func performApplyConfigState(
        _ state: ApplyConfigState,
        setName: (String) -> Void,
        setEmail: (String) -> Void,
        postUpdateNotification: () -> Void
    ) {
        performIdentity(state.identity, setName: setName, setEmail: setEmail)

        if state.postsUpdateNotification {
            postUpdateNotification()
        }
    }

    public static func postDidUpdateGitUserConfigNotification(
        center: NotificationCenter = .default
    ) {
        center.post(name: .didUpdateGitUserConfigFromCommitPackage, object: nil)
    }

    public static func performApplyConfigOperation(
        requestState: ApplyConfigRequestState,
        name: String,
        email: String,
        apply: (Identity) async throws -> Void,
        applySuccess: (ApplyConfigState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        guard requestState.shouldApply else {
            return
        }

        do {
            let identity = identity(name: name, email: email)
            try await apply(identity)
            await applySuccess(applyConfigSuccessState(name: identity.name, email: identity.email))
        } catch {
            await handleFailure(error)
        }
    }

    public static func performApplyConfigOperation(
        request: ApplyConfigRequest,
        handlers: ApplyConfigHandlers,
        applySuccess: (ApplyConfigState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performApplyConfigOperation(
            requestState: request.state,
            name: request.name,
            email: request.email,
            apply: handlers.apply,
            applySuccess: applySuccess,
            handleFailure: handleFailure
        )
    }

    public static func applyConfigHandlers<Project>(
        for project: Project,
        handlers: ProjectApplyConfigHandlers<Project>
    ) -> ApplyConfigHandlers {
        ApplyConfigHandlers { identity in
            try await handlers.apply(project, identity)
        }
    }

    public static func performApplyConfigOperation<Project>(
        command: ProjectApplyConfigRequest<Project>,
        handlers: ProjectApplyConfigHandlers<Project>,
        applySuccess: (ApplyConfigState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performApplyConfigOperation(
            request: command.request,
            handlers: applyConfigHandlers(for: command.project, handlers: handlers),
            applySuccess: applySuccess,
            handleFailure: handleFailure
        )
    }
}

public extension Notification.Name {
    static let didUpdateGitUserConfigFromCommitPackage = Notification.Name(
        CommitUserConfigRules.didUpdateGitUserConfigNotificationName
    )
}
