@testable import PluginCommit
import Foundation
import ProjectSupportKit
import SwiftUI
import Testing

@Suite("PluginCommit")
struct CommitPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(CommitPlugin.metadata.id == "CommitPlugin")
        #expect(CommitPlugin.metadata.iconName == "arrow.up.arrow.down")
        #expect(CommitPlugin.metadata.allowUserToggle == false)
        #expect(CommitPlugin.metadata.defaultEnabled == true)
        #expect(CommitPlugin.metadata.tableName == "GitCommit")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(CommitPlugin.metadata.displayName.isEmpty == false)
        #expect(CommitPlugin.metadata.description.isEmpty == false)
    }

    @Test("commit alert rules normalize failure presentation")
    func commitAlertRules() {
        struct AlertError: LocalizedError {
            var errorDescription: String? { "operation failed" }
        }

        #expect(CommitAlertRules.errorMessage(from: AlertError()) == "operation failed")
        var alertMessages: [String] = []
        CommitAlertRules.performError(AlertError()) {
            alertMessages.append($0)
        }
        CommitAlertRules.performMessage("validation failed") {
            alertMessages.append($0)
        }
        var infoMessages: [String] = []
        CommitAlertRules.performInfo("commit succeeded") {
            infoMessages.append($0)
        }
        #expect(alertMessages == ["operation failed", "validation failed"])
        #expect(infoMessages == ["commit succeeded"])
    }

    @Test("commit style formatting remains stable")
    func commitStyleFormatting() {
        #expect(CommitCategory.Feature.text(style: .emoji) == "🆕 Feature: ")
        #expect(CommitCategory.Feature.text(style: .plain) == "Feature: ")
        #expect(CommitCategory.Feature.text(style: .lowercase) == "feature: ")
    }

    @Test("commit style raw values stay compatible with persisted settings")
    func commitStyleRawValues() {
        #expect(CommitStyle(rawValue: "Emoji风格") == .emoji)
        #expect(CommitStyle(rawValue: "纯文本风格") == .plain)
        #expect(CommitStyle(rawValue: "纯文本小写") == .lowercase)
    }

    @Test("commit repo persists selected hash")
    func commitRepoPersistsSelectedHash() {
        let projectPath = "/tmp/gitok-plugin-commit-tests-\(UUID().uuidString)"
        let repo = GitCommitRepo.shared

        repo.clearLastSelectedCommit(projectPath: projectPath)
        #expect(repo.getLastSelectedCommitHash(projectPath: projectPath) == nil)

        repo.saveLastSelectedCommit(
            projectPath: projectPath,
            hash: "abc123",
            message: "Test commit",
            author: "Tester",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(repo.getLastSelectedCommitHash(projectPath: projectPath) == "abc123")
        repo.clearLastSelectedCommit(projectPath: projectPath)
    }

    @Test("commit user preset keeps stable identity fields")
    func commitUserPresetIdentity() async {
        let preset = CommitUserPreset(id: "user-1", name: "Ada", email: "ada@example.com")

        #expect(CommitUserPreset.recentConfigLimit == 10)
        #expect(CommitUserConfigRules.didUpdateGitUserConfigNotificationName == "didUpdateGitUserConfig")
        #expect(Notification.Name.didUpdateGitUserConfigFromCommitPackage.rawValue == "didUpdateGitUserConfig")
        #expect(CommitUserConfigRules.savedConfigsLoadedLogMessage(count: 2) == "Loaded 2 saved configs")
        #expect(CommitUserConfigRules.savedConfigsLoadFailureLogMessage(errorDescription: "boom").contains("boom"))
        #expect(CommitUserConfigRules.appliedConfigLogMessage(name: "Ada", email: "ada@example.com").contains("Ada"))
        #expect(CommitUserConfigRules.applyConfigFailureLogMessage(errorDescription: "boom").contains("boom"))
        #expect(preset.id == "user-1")
        #expect(preset.name == "Ada")
        #expect(preset.email == "ada@example.com")
        #expect(preset.matchesConfig(id: "user-1", name: "Other", email: "other@example.com"))
        #expect(preset.matchesConfig(id: "other", name: "Ada", email: "ada@example.com"))
        #expect(preset.matchesConfig(id: "other", name: "Ada", email: "other@example.com") == false)
        #expect(CommitUserPreset.isSameUser(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Ada",
            candidateEmail: "ada@example.com"
        ))
        #expect(CommitUserPreset.isSameUser(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Grace",
            candidateEmail: "ada@example.com"
        ) == false)
        #expect(CommitUserConfigRules.identity(name: nil, email: nil) == .init(name: "", email: ""))
        #expect(CommitUserConfigRules.identity(name: "Ada", email: nil) == .init(name: "Ada", email: ""))
        var appliedNames: [String] = []
        var appliedEmails: [String] = []
        CommitUserConfigRules.performIdentity(
            .init(name: "Ada", email: "ada@example.com"),
            setName: { appliedNames.append($0) },
            setEmail: { appliedEmails.append($0) }
        )
        #expect(appliedNames == ["Ada"])
        #expect(appliedEmails == ["ada@example.com"])
        CommitUserConfigRules.performIdentityLoad(
            loadName: { "Grace" },
            loadEmail: { "grace@example.com" },
            applyIdentity: {
                appliedNames.append($0.name)
                appliedEmails.append($0.email)
            }
        )
        #expect(appliedNames == ["Ada", "Grace"])
        #expect(appliedEmails == ["ada@example.com", "grace@example.com"])
        CommitUserConfigRules.performIdentityLoad(
            loadName: { throw NSError(domain: "GitOKTests", code: 1) },
            loadEmail: { "ignored@example.com" },
            applyIdentity: {
                appliedNames.append($0.name)
                appliedEmails.append($0.email)
            }
        )
        #expect(appliedNames == ["Ada", "Grace", ""])
        #expect(appliedEmails == ["ada@example.com", "grace@example.com", ""])
        var projectIdentityLoads: [String] = []
        CommitUserConfigRules.performProjectIdentityLoad(
            project: Optional("repo"),
            loadName: { project in
                projectIdentityLoads.append("name:\(project)")
                return "Linus"
            },
            loadEmail: { project in
                projectIdentityLoads.append("email:\(project)")
                return "linus@example.com"
            },
            applyIdentity: {
                appliedNames.append($0.name)
                appliedEmails.append($0.email)
            }
        )
        #expect(projectIdentityLoads == ["name:repo", "email:repo"])
        #expect(appliedNames.last == "Linus")
        #expect(appliedEmails.last == "linus@example.com")
        projectIdentityLoads.removeAll()
        CommitUserConfigRules.performProjectIdentityLoad(
            project: Optional<String>.none,
            loadName: { project in
                projectIdentityLoads.append("name:\(project)")
                return "Ignored"
            },
            loadEmail: { project in
                projectIdentityLoads.append("email:\(project)")
                return "ignored@example.com"
            },
            applyIdentity: {
                appliedNames.append($0.name)
                appliedEmails.append($0.email)
            }
        )
        #expect(projectIdentityLoads.isEmpty)
        #expect(appliedNames.last == "")
        #expect(appliedEmails.last == "")
        #expect(CommitUserConfigRules.shouldApplyConfig(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Grace",
            candidateEmail: "grace@example.com"
        ))
        #expect(CommitUserConfigRules.shouldApplyConfig(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Ada",
            candidateEmail: "ada@example.com"
        ) == false)
        #expect(CommitUserConfigRules.applyConfigRequestState(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Grace",
            candidateEmail: "grace@example.com"
        ) == .init(shouldApply: true))
        #expect(CommitUserConfigRules.applyConfigRequestState(
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Ada",
            candidateEmail: "ada@example.com"
        ) == .init(shouldApply: false))
        var applyRequestCount = 0
        #expect(CommitUserConfigRules.performApplyConfigRequestState(
            .init(shouldApply: false),
            perform: { applyRequestCount += 1 }
        ) == false)
        #expect(applyRequestCount == 0)
        #expect(CommitUserConfigRules.performApplyConfigRequestState(
            .init(shouldApply: true),
            perform: { applyRequestCount += 1 }
        ))
        #expect(applyRequestCount == 1)
        var requiredConfigProjectEvents: [String] = []
        #expect(CommitUserConfigRules.performRequiredProject(Optional<String>.none) {
            requiredConfigProjectEvents.append($0)
        } == false)
        #expect(CommitUserConfigRules.performRequiredProject(Optional("repo")) {
            requiredConfigProjectEvents.append($0)
        })
        #expect(requiredConfigProjectEvents == ["repo"])
        var requiredApplyConfigEvents: [String] = []
        #expect(CommitUserConfigRules.performRequiredProjectApplyConfig(
            project: Optional<String>.none,
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Grace",
            candidateEmail: "grace@example.com",
            perform: { request, project in
                requiredApplyConfigEvents.append("\(project):\(request.name):\(request.email):\(request.state.shouldApply)")
            }
        ) == false)
        #expect(CommitUserConfigRules.performRequiredProjectApplyConfig(
            project: Optional("repo"),
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Ada",
            candidateEmail: "ada@example.com",
            perform: { request, project in
                requiredApplyConfigEvents.append("\(project):\(request.name):\(request.email):\(request.state.shouldApply)")
            }
        ))
        let didApplyTupleConfig = CommitUserConfigRules.performRequiredProjectApplyConfig(
            project: Optional("repo"),
            currentName: "Ada",
            currentEmail: "ada@example.com",
            config: (name: "Grace", email: "grace@example.com"),
            candidateName: { $0.name },
            candidateEmail: { $0.email },
            perform: { request, project in
                requiredApplyConfigEvents.append("\(project):\(request.name):\(request.email):\(request.state.shouldApply)")
            }
        )
        #expect(didApplyTupleConfig)
        #expect(requiredApplyConfigEvents == [
            "repo:Ada:ada@example.com:false",
            "repo:Grace:grace@example.com:true",
        ])
        var requiredApplyConfigCommandEvents: [String] = []
        #expect(CommitUserConfigRules.performRequiredProjectApplyConfigCommand(
            project: Optional<String>.none,
            currentName: "Ada",
            currentEmail: "ada@example.com",
            candidateName: "Grace",
            candidateEmail: "grace@example.com",
            perform: { command in
                requiredApplyConfigCommandEvents.append("\(command.project):\(command.request.name):\(command.request.email):\(command.request.state.shouldApply)")
            }
        ) == false)
        #expect(CommitUserConfigRules.performRequiredProjectApplyConfigCommand(
            project: Optional("repo"),
            currentName: "Ada",
            currentEmail: "ada@example.com",
            config: (name: "Grace", email: "grace@example.com"),
            candidateName: { $0.name },
            candidateEmail: { $0.email },
            perform: { command in
                requiredApplyConfigCommandEvents.append("\(command.project):\(command.request.name):\(command.request.email):\(command.request.state.shouldApply)")
            }
        ))
        #expect(requiredApplyConfigCommandEvents == [
            "repo:Grace:grace@example.com:true",
        ])
        #expect(CommitUserConfigRules.applyConfigSuccessState(
            name: "Grace",
            email: "grace@example.com"
        ) == .init(
            identity: .init(name: "Grace", email: "grace@example.com"),
            postsUpdateNotification: true
        ))
        var notificationCount = 0
        CommitUserConfigRules.performApplyConfigState(
            CommitUserConfigRules.applyConfigSuccessState(name: "Grace", email: "grace@example.com"),
            setName: { appliedNames.append($0) },
            setEmail: { appliedEmails.append($0) },
            postUpdateNotification: { notificationCount += 1 }
        )
        #expect(appliedNames.last == "Grace")
        #expect(appliedEmails.last == "grace@example.com")
        #expect(notificationCount == 1)
        let notificationCenter = NotificationCenter()
        final class NotificationRecorder: @unchecked Sendable {
            private let lock = NSLock()
            private var values: [Notification.Name] = []

            func append(_ value: Notification.Name) {
                lock.withLock {
                    values.append(value)
                }
            }

            var snapshot: [Notification.Name] {
                lock.withLock {
                    values
                }
            }
        }

        let notificationRecorder = NotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .didUpdateGitUserConfigFromCommitPackage,
            object: nil,
            queue: nil
        ) { notification in
            notificationRecorder.append(notification.name)
        }
        CommitUserConfigRules.postDidUpdateGitUserConfigNotification(center: notificationCenter)
        notificationCenter.removeObserver(observer)
        #expect(notificationRecorder.snapshot == [.didUpdateGitUserConfigFromCommitPackage])
        var loadedConfigBatches: [[String]] = []
        var savedConfigLoadEvents: [String] = []
        CommitUserConfigRules.performSavedConfigsLoad(
            limit: 2,
            loadConfigs: { limit in Array(["Ada", "Grace", "Linus"].prefix(limit)) },
            applyConfigs: { loadedConfigBatches.append($0) },
            logSuccess: { savedConfigLoadEvents.append("success:\($0)") },
            logFailure: { savedConfigLoadEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(loadedConfigBatches == [["Ada", "Grace"]])
        #expect(savedConfigLoadEvents == ["success:2"])
        CommitUserConfigRules.performSavedConfigsLoad(
            limit: 2,
            loadConfigs: { _ in throw NSError(domain: "GitOKTests", code: 2) },
            applyConfigs: { loadedConfigBatches.append($0) },
            logSuccess: { savedConfigLoadEvents.append("success:\($0)") },
            logFailure: { savedConfigLoadEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(loadedConfigBatches == [["Ada", "Grace"]])
        #expect(savedConfigLoadEvents.count == 2)
        var initialLoadEvents: [String] = []
        CommitUserConfigRules.performInitialUserViewLoad(
            limit: 2,
            loadName: {
                initialLoadEvents.append("load-name")
                return "Ada"
            },
            loadEmail: {
                initialLoadEvents.append("load-email")
                return "ada@example.com"
            },
            applyIdentity: { identity in
                initialLoadEvents.append("identity:\(identity.name):\(identity.email)")
            },
            loadConfigs: { limit in
                initialLoadEvents.append("load-configs:\(limit)")
                return ["Ada", "Grace"]
            },
            applyConfigs: { configs in
                initialLoadEvents.append("configs:\(configs.joined(separator: ","))")
            },
            logConfigSuccess: { count in
                initialLoadEvents.append("success:\(count)")
            },
            logConfigFailure: { error in
                initialLoadEvents.append("failure:\(error.localizedDescription)")
            }
        )
        #expect(initialLoadEvents == [
            "load-name",
            "load-email",
            "identity:Ada:ada@example.com",
            "load-configs:2",
            "configs:Ada,Grace",
            "success:2",
        ])
        initialLoadEvents.removeAll()
        CommitUserConfigRules.performInitialUserViewLoad(
            project: Optional("repo"),
            limit: 1,
            loadName: { project in
                initialLoadEvents.append("load-name:\(project)")
                return "Grace"
            },
            loadEmail: { project in
                initialLoadEvents.append("load-email:\(project)")
                return "grace@example.com"
            },
            applyIdentity: { identity in
                initialLoadEvents.append("identity:\(identity.name):\(identity.email)")
            },
            loadConfigs: { limit in
                initialLoadEvents.append("load-configs:\(limit)")
                return ["Grace"]
            },
            applyConfigs: { configs in
                initialLoadEvents.append("configs:\(configs.joined(separator: ","))")
            },
            logConfigSuccess: { count in
                initialLoadEvents.append("success:\(count)")
            },
            logConfigFailure: { error in
                initialLoadEvents.append("failure:\(error.localizedDescription)")
            }
        )
        #expect(initialLoadEvents == [
            "load-name:repo",
            "load-email:repo",
            "identity:Grace:grace@example.com",
            "load-configs:1",
            "configs:Grace",
            "success:1",
        ])
        initialLoadEvents.removeAll()
        CommitUserConfigRules.performUserViewAppear {
            initialLoadEvents.append("initial")
        }
        CommitUserConfigRules.performSettingsDisappear(
            loadUserInfo: { initialLoadEvents.append("user") },
            loadSavedConfigs: { initialLoadEvents.append("configs") }
        )
        #expect(initialLoadEvents == ["initial", "user", "configs"])
        var configOperationEvents: [String] = []
        await CommitUserConfigRules.performApplyConfigOperation(
            requestState: .init(shouldApply: true),
            name: "Linus",
            email: "linus@example.com",
            apply: { identity in configOperationEvents.append("apply:\(identity.name)") },
            applySuccess: { state in configOperationEvents.append("success:\(state.identity.email)") },
            handleFailure: { configOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(configOperationEvents == ["apply:Linus", "success:linus@example.com"])
        await CommitUserConfigRules.performApplyConfigOperation(
            requestState: .init(shouldApply: false),
            name: "Skip",
            email: "skip@example.com",
            apply: { identity in configOperationEvents.append("apply:\(identity.name)") },
            applySuccess: { state in configOperationEvents.append("success:\(state.identity.email)") },
            handleFailure: { configOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(configOperationEvents == ["apply:Linus", "success:linus@example.com"])
        enum ConfigOperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "config failed"
            }
        }
        await CommitUserConfigRules.performApplyConfigOperation(
            requestState: .init(shouldApply: true),
            name: "Broken",
            email: "broken@example.com",
            apply: { _ in throw ConfigOperationError.failed },
            applySuccess: { state in configOperationEvents.append("success:\(state.identity.email)") },
            handleFailure: { configOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(configOperationEvents == [
            "apply:Linus",
            "success:linus@example.com",
            "failure:config failed",
        ])
        let configHandlers = CommitUserConfigRules.ApplyConfigHandlers { identity in
            configOperationEvents.append("handler-apply:\(identity.name)")
        }
        await CommitUserConfigRules.performApplyConfigOperation(
            request: .init(
                state: .init(shouldApply: true),
                name: "Ada",
                email: "ada@example.com"
            ),
            handlers: configHandlers,
            applySuccess: { state in configOperationEvents.append("handler-success:\(state.identity.email)") },
            handleFailure: { configOperationEvents.append("handler-failure:\($0.localizedDescription)") }
        )
        #expect(configOperationEvents == [
            "apply:Linus",
            "success:linus@example.com",
            "failure:config failed",
            "handler-apply:Ada",
            "handler-success:ada@example.com",
        ])
        let projectConfigHandlers = CommitUserConfigRules.ProjectApplyConfigHandlers<String> { project, identity in
            configOperationEvents.append("project-handler-apply:\(project):\(identity.name)")
        }
        await CommitUserConfigRules.performApplyConfigOperation(
            command: .init(
                request: .init(
                    state: .init(shouldApply: true),
                    name: "Grace",
                    email: "grace@example.com"
                ),
                project: "repo"
            ),
            handlers: projectConfigHandlers,
            applySuccess: { state in configOperationEvents.append("project-handler-success:\(state.identity.email)") },
            handleFailure: { configOperationEvents.append("project-handler-failure:\($0.localizedDescription)") }
        )
        #expect(configOperationEvents == [
            "apply:Linus",
            "success:linus@example.com",
            "failure:config failed",
            "handler-apply:Ada",
            "handler-success:ada@example.com",
            "project-handler-apply:repo:Grace",
            "project-handler-success:grace@example.com",
        ])

        let presets = CommitUserPreset.presets(configs: [
            (id: 1, name: "Grace", email: "grace@example.com"),
            (id: 2, name: "Linus", email: "linus@example.com"),
        ])

        #expect(presets.map(\.id) == ["1", "2"])
        #expect(presets.map(\.name) == ["Grace", "Linus"])
        #expect(CommitUserConfigRules.presets(from: [
            .init(id: "1", name: "Grace", email: "grace@example.com"),
            .init(id: "2", name: "Linus", email: "linus@example.com"),
        ]) == presets)
        #expect(CommitUserConfigRules.configCandidates(from: [
            (id: 1, name: "Grace", email: "grace@example.com"),
            (id: 2, name: "Linus", email: "linus@example.com"),
        ]) == [
            .init(id: "1", name: "Grace", email: "grace@example.com"),
            .init(id: "2", name: "Linus", email: "linus@example.com"),
        ])
        #expect(CommitUserConfigRules.savedConfigPresentationState(configs: [
            (id: 1, name: "Grace", email: "grace@example.com"),
            (id: 2, name: "Linus", email: "linus@example.com"),
        ]) == .init(
            candidates: [
                .init(id: "1", name: "Grace", email: "grace@example.com"),
                .init(id: "2", name: "Linus", email: "linus@example.com"),
            ],
            presets: presets
        ))
        #expect(CommitUserConfigRules.matchingConfigID(
            for: presets[0],
            candidates: [
                .init(id: "2", name: "Linus", email: "linus@example.com"),
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ]
        ) == "1")
        #expect(CommitUserConfigRules.matchingConfigID(
            for: .init(id: "missing", name: "Missing", email: "missing@example.com"),
            candidates: [
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ]
        ) == nil)
        #expect(CommitUserConfigRules.firstItem(
            matchingID: "2",
            in: [1, 2, 3],
            id: { $0 }
        ) == 2)
        #expect(CommitUserConfigRules.matchingItem(
            for: presets[0],
            candidates: [
                .init(id: "2", name: "Linus", email: "linus@example.com"),
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ],
            in: [1, 2, 3],
            id: { $0 }
        ) == 1)
        #expect(CommitUserConfigRules.matchingItem(
            for: .init(id: "missing", name: "Missing", email: "missing@example.com"),
            candidates: [
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ],
            in: [1, 2, 3],
            id: { $0 }
        ) == nil)
        var matchingPresetEvents: [Int] = []
        #expect(CommitUserConfigRules.performMatchingPreset(
            presets[0],
            candidates: [
                .init(id: "2", name: "Linus", email: "linus@example.com"),
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ],
            in: [1, 2, 3],
            id: { $0 },
            perform: { matchingPresetEvents.append($0) }
        ))
        #expect(CommitUserConfigRules.performMatchingPreset(
            .init(id: "missing", name: "Missing", email: "missing@example.com"),
            candidates: [
                .init(id: "1", name: "Grace", email: "grace@example.com"),
            ],
            in: [1, 2, 3],
            id: { $0 },
            perform: { matchingPresetEvents.append($0) }
        ) == false)
        #expect(matchingPresetEvents == [1])
        #expect(CommitUserConfigRules.firstItem(
            matchingID: "missing",
            in: [1, 2, 3],
            id: { $0 }
        ) == nil)
    }

    @Test("commit user config host view is constructible from app adapters")
    @MainActor
    func commitUserConfigHostViewConstructsFromAdapters() {
        let view = CommitUserConfigHostView<String, (id: Int, name: String, email: String), Int, EmptyView>(
            project: "repo",
            configID: \.id,
            configName: \.name,
            configEmail: \.email,
            loadProjectUserName: { _ in "Ada" },
            loadProjectUserEmail: { _ in "ada@example.com" },
            loadRecentConfigs: { limit in
                Array([(id: 1, name: "Ada", email: "ada@example.com")].prefix(limit))
            },
            applyProjectConfig: { _, _ in },
            settingsContent: { EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("commit form host view is constructible from app adapters")
    @MainActor
    func commitFormHostViewConstructsFromAdapters() {
        struct Branch {
            let name: String
        }

        let view = CommitFormHostView<String, Branch, EmptyView>(
            project: "repo",
            projectStyle: { _ in .emoji },
            saveProjectStyle: { _, _ in },
            loadCoAuthors: { [] },
            loadLocalBranches: { _ in [Branch(name: "feature/123")] },
            localBranchName: \.name,
            loadRemoteBranches: { _ in ["origin/main"] },
            hasStagedChanges: { _ in true },
            addAllFiles: { _ in },
            commit: { _, _ in },
            push: { _ in },
            setActivityStatus: { _ in },
            userContent: { EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("commit list host view is constructible from app adapters")
    @MainActor
    func commitListHostViewConstructsFromAdapters() {
        struct CommitFixture {
            let hash: String
            let parentHashes: [String]
        }

        let view = CommitListHostView<String, CommitFixture, CommitFixture, EmptyView, EmptyView>(
            project: "repo",
            projectPath: { $0 },
            loadItems: { _, _, _ in [CommitFixture(hash: "abc", parentHashes: [])] },
            loadUnpushedItems: { _ in [CommitFixture(hash: "abc", parentHashes: [])] },
            itemID: \.hash,
            itemParentIDs: \.parentHashes,
            unpushedID: \.hash,
            updateUnpushed: { _, _ in },
            selectItem: { _ in },
            loadLastSelectedID: { _ in nil },
            workingStateContent: { _ in EmptyView() },
            rowContent: { _, _, _, _, _ in EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("working state host view is constructible from app adapters")
    @MainActor
    func workingStateHostViewConstructsFromAdapters() {
        struct CommitFixture {
            let hash: String
        }

        let view = WorkingStateHostView<String, CommitFixture, EmptyView>(
            project: "repo",
            selectedCommit: nil,
            setSelectedCommit: { _ in },
            setActivityStatus: { _ in },
            updateCleanState: { _ in },
            projectPath: { $0 },
            loadChangedFileCount: { _ in 0 },
            loadUnpushedCommits: { _ in [CommitFixture(hash: "abc")] },
            loadUnpulledCount: { _ in 0 },
            pull: { _ in },
            push: { _ in },
            pushErrorClassification: { _ in
                CommitRemoteSyncRules.PushErrorClassification(
                    isNetworkError: false,
                    isAuthenticationError: false,
                    isRetryablePushError: false
                )
            },
            runNetworkFallback: { _, _, _ in false },
            currentRemoteAccess: { .empty },
            showNetworkFallbackSelection: { _ in .cancel },
            sshHelpContent: { _, _, _ in EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("commit row host view is constructible from app adapters")
    @MainActor
    func commitRowHostViewConstructsFromAdapters() {
        struct CommitFixture {
            let hash: String
            let message: String
            let author: String
            let parentHashes: [String]
            let tags: [String]
        }

        let commit = CommitFixture(
            hash: "abc123",
            message: "Add host view",
            author: "Ada <ada@example.com>",
            parentHashes: ["parent"],
            tags: []
        )

        let view = CommitRowHostView<String, CommitFixture>(
            project: "repo",
            commit: commit,
            isFirstCommit: true,
            commitIndex: 0,
            graphRow: nil,
            graphLaneCount: 1,
            currentCommitID: nil,
            isCommitUnpushed: { _ in true },
            selectCommit: { _ in },
            commitHash: \.hash,
            commitMessage: \.message,
            commitAuthor: \.author,
            commitAllAuthors: \.author,
            commitRelativeTime: { _ in "now" },
            commitFullDateTime: { _ in "2026-05-31" },
            commitParentHashes: \.parentHashes,
            commitTagCount: { $0.tags.count },
            projectPath: { $0 },
            pushProject: { _ in },
            undoCommit: { _, _ in },
            revertCommit: { _, _ in },
            resetToCommit: { _, _, _ in },
            squashLastCommits: { _, _ in },
            loadTags: { _, _ in [] },
            createLightweightTag: { _, _, _ in },
            createAnnotatedTag: { _, _, _, _ in },
            deleteLocalTag: { _, _ in },
            pushTagOperation: { _, _ in },
            deleteRemoteTag: { _, _ in }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("commit author parser extracts primary author and coauthors")
    func commitAuthorParserExtractsAuthors() {
        let users = CommitAuthorParser.avatarUsers(
            author: "Ada Lovelace <ada@example.com>",
            message: """
            Add analytical engine notes

            Co-authored-by: Grace Hopper <grace@example.com>
            Co-authored-by: Ada Lovelace <ada@example.com>
            """
        )

        #expect(users.map(\.name) == ["Ada Lovelace", "Grace Hopper"])
        #expect(users.map(\.email) == ["ada@example.com", "grace@example.com"])
    }

    @Test("commit author parser performs avatar user load")
    func commitAuthorParserPerformsAvatarUsersLoad() async {
        var events: [String] = []
        var loadedUsers: [AvatarUser] = []

        await CommitAuthorParser.performAvatarUsersLoad(
            author: "Ada Lovelace <ada@example.com>",
            message: """
            Add analytical engine notes

            Co-authored-by: Grace Hopper <grace@example.com>
            Co-authored-by: Ada Lovelace <ada@example.com>
            """,
            logStart: {
                events.append("start")
            },
            logCoAuthors: { count in
                events.append("coauthors:\(count)")
            },
            setUsers: { users in
                loadedUsers = users
                events.append("set:\(users.count)")
            }
        )

        #expect(events == ["start", "coauthors:1", "set:2"])
        #expect(loadedUsers.map(\.name) == ["Ada Lovelace", "Grace Hopper"])
        #expect(loadedUsers.map(\.email) == ["ada@example.com", "grace@example.com"])
    }

    @Test("commit row load rules initialize avatar users and visible tag")
    func commitRowLoadRulesInitialLoad() async {
        var events: [String] = []
        var loadedUsers: [AvatarUser] = []
        var loadedTag = ""

        CommitRowLoadRules.performAppear {
            events.append("appear")
        }
        #expect(events == ["appear"])
        events = []

        await CommitRowLoadRules.performInitialLoad(
            author: "Ada Lovelace <ada@example.com>",
            message: """
            Add analytical engine notes

            Co-authored-by: Grace Hopper <grace@example.com>
            """,
            loadTags: {
                events.append("load-tags")
                return ["v1.0.0"]
            },
            logAvatarStart: {
                events.append("avatar-start")
            },
            logAvatarCoAuthors: { count in
                events.append("coauthors:\(count)")
            },
            setAvatarUsers: { users in
                loadedUsers = users
                events.append("set-users:\(users.count)")
            },
            setTag: { tag in
                loadedTag = tag
                events.append("set-tag:\(tag)")
            }
        )

        #expect(events == [
            "avatar-start",
            "coauthors:1",
            "set-users:2",
            "load-tags",
            "set-tag:v1.0.0",
        ])
        #expect(loadedUsers.map(\.name) == ["Ada Lovelace", "Grace Hopper"])
        #expect(loadedTag == "v1.0.0")

        events = []
        loadedUsers = []
        loadedTag = ""
        await CommitRowLoadRules.performInitialLoad(
            author: "Ada Lovelace <ada@example.com>",
            message: "Release notes",
            commitHash: "abc123",
            loadTags: { hash in
                events.append("load-tags:\(hash)")
                return ["tag-\(hash)"]
            },
            logAvatarStart: {
                events.append("avatar-start")
            },
            logAvatarCoAuthors: { count in
                events.append("coauthors:\(count)")
            },
            setAvatarUsers: { users in
                loadedUsers = users
                events.append("set-users:\(users.count)")
            },
            setTag: { tag in
                loadedTag = tag
                events.append("set-tag:\(tag)")
            }
        )

        #expect(events == [
            "avatar-start",
            "set-users:1",
            "load-tags:abc123",
            "set-tag:tag-abc123",
        ])
        #expect(loadedUsers.map(\.name) == ["Ada Lovelace"])
        #expect(loadedTag == "tag-abc123")

        events = []
        loadedUsers = []
        loadedTag = ""
        await CommitRowLoadRules.performInitialLoad(
            author: "Ada Lovelace <ada@example.com>",
            message: "Release notes",
            commitHash: "def456",
            project: Optional("repo"),
            loadTags: { project, hash in
                events.append("load-tags:\(project):\(hash)")
                return ["\(project)-\(hash)"]
            },
            logAvatarStart: {
                events.append("avatar-start")
            },
            logAvatarCoAuthors: { count in
                events.append("coauthors:\(count)")
            },
            setAvatarUsers: { users in
                loadedUsers = users
                events.append("set-users:\(users.count)")
            },
            setTag: { tag in
                loadedTag = tag
                events.append("set-tag:\(tag)")
            }
        )

        #expect(events == [
            "avatar-start",
            "set-users:1",
            "load-tags:repo:def456",
            "set-tag:repo-def456",
        ])
        #expect(loadedUsers.map(\.name) == ["Ada Lovelace"])
        #expect(loadedTag == "repo-def456")

        events = []
        loadedUsers = []
        loadedTag = ""
        await CommitRowLoadRules.performInitialLoad(
            author: "Ada Lovelace <ada@example.com>",
            message: "Release notes",
            commitHash: "ghi789",
            project: Optional("repo"),
            handlers: CommitRowLoadRules.ProjectTagLoadHandlers { project, hash in
                events.append("handler-load-tags:\(project):\(hash)")
                return ["handler-\(project)-\(hash)"]
            },
            logAvatarStart: {
                events.append("avatar-start")
            },
            logAvatarCoAuthors: { count in
                events.append("coauthors:\(count)")
            },
            setAvatarUsers: { users in
                loadedUsers = users
                events.append("set-users:\(users.count)")
            },
            setTag: { tag in
                loadedTag = tag
                events.append("set-tag:\(tag)")
            }
        )

        #expect(events == [
            "avatar-start",
            "set-users:1",
            "handler-load-tags:repo:ghi789",
            "set-tag:handler-repo-ghi789",
        ])
        #expect(loadedUsers.map(\.name) == ["Ada Lovelace"])
        #expect(loadedTag == "handler-repo-ghi789")
    }

    @Test("commit author parser keeps name-only authors")
    func commitAuthorParserNameOnlyAuthor() {
        let user = CommitAuthorParser.primaryAuthor(from: "Build Bot")

        #expect(user.name == "Build Bot")
        #expect(user.email == "")
    }

    @Test("history action rules match commit safety constraints")
    func historyActionRules() async throws {
        #expect(CommitHistoryActionRules.errorDomain == "GitOK")
        #expect(CommitHistoryActionRules.genericErrorCode == -1)
        #expect(CommitHistoryActionRules.undoResetMode == "mixed")
        #expect(CommitHistoryActionRules.undoCommitOperation == "undoCommit")
        #expect(CommitHistoryActionRules.commitHashInfoKey == "commitHash")
        #expect(CommitHistoryActionRules.parentHashInfoKey == "parentHash")
        var pushOperationEvents: [String] = []
        try await CommitHistoryActionRules.performPushOperation(
            push: { pushOperationEvents.append("push") },
            logStart: { pushOperationEvents.append("start") },
            logSuccess: { pushOperationEvents.append("success") }
        )
        #expect(pushOperationEvents == ["start", "push", "success"])
        enum PushOperationError: Error {
            case failed
        }
        pushOperationEvents = []
        do {
            try await CommitHistoryActionRules.performPushOperation(
                push: {
                    pushOperationEvents.append("push")
                    throw PushOperationError.failed
                },
                logStart: { pushOperationEvents.append("start") },
                logSuccess: { pushOperationEvents.append("success") }
            )
        } catch {
            pushOperationEvents.append("failure")
        }
        #expect(pushOperationEvents == ["start", "push", "failure"])
        var projectPushOperationEvents: [String] = []
        try await CommitHistoryActionRules.performRequiredProjectPushOperation(
            project: Optional("repo"),
            push: { request in projectPushOperationEvents.append("push:\(request.project)") },
            logStart: { projectPushOperationEvents.append("start") },
            logSuccess: { projectPushOperationEvents.append("success") }
        )
        #expect(projectPushOperationEvents == ["start", "push:repo", "success"])
        await #expect(throws: NSError.self) {
            try await CommitHistoryActionRules.performRequiredProjectPushOperation(
                project: Optional<String>.none,
                push: { request in projectPushOperationEvents.append("push:\(request.project)") },
                logStart: { projectPushOperationEvents.append("missing-start") },
                logSuccess: { projectPushOperationEvents.append("missing-success") }
            )
        }
        #expect(projectPushOperationEvents == ["start", "push:repo", "success"])
        let undoSuccessPayload = CommitHistoryActionRules.undoSuccessEventPayload(
            commitHash: "1234567890",
            parentHash: "0987654321"
        )
        #expect(undoSuccessPayload == .init(
            operation: "undoCommit",
            additionalInfo: [
                "commitHash": "1234567890",
                "parentHash": "0987654321"
            ]
        ))
        #expect(undoSuccessPayload.projectEventAdditionalInfo["commitHash"] as? String == "1234567890")
        #expect(undoSuccessPayload.projectEventAdditionalInfo["parentHash"] as? String == "0987654321")
        let undoFailurePayload = CommitHistoryActionRules.undoFailureEventPayload(commitHash: "1234567890")
        #expect(undoFailurePayload == .init(
            operation: "undoCommit",
            additionalInfo: ["commitHash": "1234567890"]
        ))
        #expect(CommitHistoryActionRules.isCurrentProject(
            operationProjectPath: "/repo",
            currentProjectPath: "/repo"
        ))
        #expect(CommitHistoryActionRules.isCurrentProject(
            operationProjectPath: "/repo",
            currentProjectPath: "/other"
        ) == false)
        #expect(CommitHistoryActionRules.isCurrentProject(
            operationProjectPath: "/repo",
            currentProjectPath: nil
        ) == false)
        var currentProjectEvents: [String] = []
        #expect(CommitHistoryActionRules.performCurrentProject(
            operationProjectPath: "/repo",
            currentProject: Optional("/other"),
            currentProjectPath: { $0 },
            perform: { currentProjectEvents.append($0) }
        ) == false)
        #expect(CommitHistoryActionRules.performCurrentProject(
            operationProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            perform: { currentProjectEvents.append($0) }
        ))
        #expect(currentProjectEvents == ["/repo"])
        #expect(CommitHistoryActionRules.canUndoLatestCommit(
            isFirstCommit: true,
            isUnpushed: true,
            tagCount: 0,
            parentHashCount: 1
        ))
        #expect(CommitHistoryActionRules.canUndoLatestCommit(
            isFirstCommit: true,
            isUnpushed: true,
            tagCount: 1,
            parentHashCount: 1
        ) == false)
        #expect(CommitHistoryActionRules.canUndoLatestCommit(
            isFirstCommit: false,
            isUnpushed: true,
            tagCount: 0,
            parentHashCount: 1
        ) == false)
        #expect(CommitHistoryActionRules.canUndoLatestCommit(
            isFirstCommit: true,
            isUnpushed: true,
            tagCount: 0,
            parentHashCount: 0
        ) == false)
        #expect(CommitHistoryActionRules.canSquashThroughHead(commitIndex: 1, isUnpushed: true))
        #expect(CommitHistoryActionRules.canSquashThroughHead(commitIndex: 0, isUnpushed: true) == false)
        #expect(CommitHistoryActionRules.canSquashThroughHead(commitIndex: 2, isUnpushed: false) == false)
        #expect(CommitHistoryActionRules.squashCountThroughHead(commitIndex: 0) == 1)
        #expect(CommitHistoryActionRules.squashCountThroughHead(commitIndex: 3) == 4)
        #expect(CommitHistoryActionRules.squashPromptState(commitMessage: "Combine changes") == .init(
            showsPrompt: true,
            message: "Combine changes"
        ))
        #expect(CommitHistoryActionRules.confirmationPromptState() == .init(showsPrompt: true))
        var historyPrompts: [String] = []
        CommitHistoryActionRules.performUndoPrompt { historyPrompts.append("undo:\($0)") }
        CommitHistoryActionRules.performRevertPrompt { historyPrompts.append("revert:\($0)") }
        CommitHistoryActionRules.performSoftResetPrompt { historyPrompts.append("soft:\($0)") }
        CommitHistoryActionRules.performMixedResetPrompt { historyPrompts.append("mixed:\($0)") }
        CommitHistoryActionRules.performHardResetPrompt { historyPrompts.append("hard:\($0)") }
        #expect(historyPrompts == [
            "undo:true",
            "revert:true",
            "soft:true",
            "mixed:true",
            "hard:true",
        ])
        var appliedSquashMessage = ""
        var appliedSquashPresented = false
        CommitHistoryActionRules.performSquashPromptState(
            CommitHistoryActionRules.squashPromptState(commitMessage: "Combine changes"),
            setMessage: { appliedSquashMessage = $0 },
            setPresented: { appliedSquashPresented = $0 }
        )
        #expect(appliedSquashMessage == "Combine changes")
        #expect(appliedSquashPresented)
        #expect(CommitHistoryActionRules.undoRequestState(parentHashes: ["parent", "grandparent"]) == .init(
            parentHash: "parent",
            errorMessage: nil
        ))
        let initialCommitUndoRequest = CommitHistoryActionRules.undoRequestState(parentHashes: [])
        #expect(initialCommitUndoRequest.canPerform == false)
        #expect(initialCommitUndoRequest.parentHash == nil)
        #expect(initialCommitUndoRequest.errorMessage == CommitHistoryActionRules.undoInitialCommitUnsupportedMessage())
        #expect(CommitHistoryActionRules.validationFailureMessage(
            for: initialCommitUndoRequest
        ) == CommitHistoryActionRules.undoInitialCommitUnsupportedMessage())
        let initialCommitUndoError = CommitHistoryActionRules.validationFailureError(for: initialCommitUndoRequest)
        #expect(initialCommitUndoError?.domain == CommitHistoryActionRules.errorDomain)
        #expect(initialCommitUndoError?.localizedDescription == CommitHistoryActionRules.undoInitialCommitUnsupportedMessage())
        let validatedParentHash = try CommitHistoryActionRules.validatedParentHash(
            for: CommitHistoryActionRules.undoRequestState(parentHashes: ["parent"])
        )
        #expect(validatedParentHash == "parent")
        #expect(throws: NSError.self) {
            try CommitHistoryActionRules.validatedParentHash(for: initialCommitUndoRequest)
        }
        #expect(CommitHistoryActionRules.startState(for: .undo) == .init(
            isRunningHistoryOperation: false,
            isUndoing: true,
            closesUndoConfirmation: false,
            closesRevertConfirmation: false,
            closesResetConfirmations: false,
            closesSquashConfirmation: false,
            clearsSelectedCommit: false
        ))
        #expect(CommitHistoryActionRules.startState(for: .squash) == .init(
            isRunningHistoryOperation: true,
            isUndoing: false,
            closesUndoConfirmation: false,
            closesRevertConfirmation: false,
            closesResetConfirmations: false,
            closesSquashConfirmation: false,
            clearsSelectedCommit: false
        ))
        #expect(CommitHistoryActionRules.completionState(
            for: .revert,
            succeeded: true
        ) == .init(
            isRunningHistoryOperation: false,
            isUndoing: false,
            closesUndoConfirmation: false,
            closesRevertConfirmation: true,
            closesResetConfirmations: false,
            closesSquashConfirmation: false,
            clearsSelectedCommit: true
        ))
        #expect(CommitHistoryActionRules.completionState(
            for: .undo,
            succeeded: false
        ) == .init(
            isRunningHistoryOperation: false,
            isUndoing: false,
            closesUndoConfirmation: true,
            closesRevertConfirmation: false,
            closesResetConfirmations: false,
            closesSquashConfirmation: false,
            clearsSelectedCommit: false
        ))
        #expect(CommitHistoryActionRules.completionState(
            for: .reset,
            succeeded: false
        ) == .init(
            isRunningHistoryOperation: false,
            isUndoing: false,
            closesUndoConfirmation: false,
            closesRevertConfirmation: false,
            closesResetConfirmations: true,
            closesSquashConfirmation: false,
            clearsSelectedCommit: false
        ))
        #expect(CommitHistoryActionRules.normalizedSquashMessage("  combine commits\n") == "combine commits")
        #expect(CommitHistoryActionRules.canSquash(message: " combine "))
        #expect(CommitHistoryActionRules.canSquash(message: " \n\t ") == false)
        #expect(CommitHistoryActionRules.squashValidation(
            message: " combine commits\n",
            commitIndex: 2
        ) == .init(
            message: "combine commits",
            count: 3,
            errorMessage: nil
        ))
        #expect(CommitHistoryActionRules.squashValidation(
            message: " \n\t ",
            commitIndex: 2
        ).canProceed == false)
        let invalidSquashValidation = CommitHistoryActionRules.squashValidation(
            message: " \n\t ",
            commitIndex: 2
        )
        #expect(invalidSquashValidation.errorMessage?.isEmpty == false)
        #expect(CommitHistoryActionRules.validationFailureMessage(
            for: invalidSquashValidation
        ) == CommitHistoryActionRules.squashMessageRequiredMessage())
        #expect(CommitHistoryActionRules.validationFailureMessage(
            for: CommitHistoryActionRules.squashValidation(message: "combine", commitIndex: 2)
        ) == nil)
        var squashValidationFailures: [String] = []
        var squashStartStates: [CommitHistoryActionRules.CompletionState] = []
        #expect(CommitHistoryActionRules.performValidatedSquash(
            invalidSquashValidation,
            showValidationFailure: { squashValidationFailures.append($0) },
            applyStartState: { squashStartStates.append($0) }
        ) == false)
        #expect(squashValidationFailures == [CommitHistoryActionRules.squashMessageRequiredMessage()])
        #expect(squashStartStates.isEmpty)
        #expect(CommitHistoryActionRules.performValidatedSquash(
            CommitHistoryActionRules.squashValidation(message: "combine", commitIndex: 2),
            showValidationFailure: { squashValidationFailures.append($0) },
            applyStartState: { squashStartStates.append($0) }
        ))
        #expect(squashStartStates == [CommitHistoryActionRules.startState(for: .squash)])
        #expect(CommitHistoryActionRules.projectUnavailableMessage().isEmpty == false)
        let operationError = CommitHistoryActionRules.operationError(message: "failed")
        #expect(operationError.domain == CommitHistoryActionRules.errorDomain)
        #expect(operationError.code == CommitHistoryActionRules.genericErrorCode)
        #expect(operationError.localizedDescription == "failed")
        #expect(CommitHistoryActionRules.projectUnavailableError().domain == CommitHistoryActionRules.errorDomain)
        #expect(CommitHistoryActionRules.projectUnavailableError().code == CommitHistoryActionRules.genericErrorCode)
        #expect(try CommitHistoryActionRules.requiredProject(Optional("repo")) == "repo")
        #expect(throws: NSError.self) {
            try CommitHistoryActionRules.requiredProject(Optional<String>.none)
        }
        var requiredProjectEvents: [String] = []
        #expect(CommitHistoryActionRules.performRequiredProject(
            Optional<String>.none,
            showUnavailable: { requiredProjectEvents.append("missing:\($0.isEmpty == false)") },
            perform: { requiredProjectEvents.append("project:\($0)") }
        ) == false)
        #expect(CommitHistoryActionRules.performRequiredProject(
            Optional("repo"),
            showUnavailable: { requiredProjectEvents.append("missing:\($0)") },
            perform: { requiredProjectEvents.append("project:\($0)") }
        ))
        #expect(requiredProjectEvents == ["missing:true", "project:repo"])
        var requiredHistoryOperationEvents: [String] = []
        #expect(CommitHistoryActionRules.performRequiredProjectHistoryOperation(
            project: Optional<String>.none,
            operation: .reset,
            commitHash: "abc123",
            resetMode: "hard",
            showUnavailable: { requiredHistoryOperationEvents.append("missing:\($0.isEmpty == false)") },
            perform: { request, project in
                requiredHistoryOperationEvents.append("\(project):\(request.operation):\(request.commitHash):\(request.resetMode ?? "nil")")
            }
        ) == false)
        #expect(CommitHistoryActionRules.performRequiredProjectHistoryOperation(
            project: Optional("repo"),
            operation: .reset,
            commitHash: "abc123",
            resetMode: "hard",
            showUnavailable: { requiredHistoryOperationEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredHistoryOperationEvents.append("\(project):\(request.operation):\(request.commitHash):\(request.resetMode ?? "nil")")
            }
        ))
        #expect(requiredHistoryOperationEvents == ["missing:true", "repo:reset:abc123:hard"])
        var requiredSquashProjectEvents: [String] = []
        #expect(CommitHistoryActionRules.performRequiredProjectHistoryOperation(
            project: Optional("repo"),
            operation: .squash,
            commitHash: "def456",
            squashValidation: CommitHistoryActionRules.squashValidation(message: "combine", commitIndex: 2),
            showUnavailable: { requiredSquashProjectEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredSquashProjectEvents.append("\(project):\(request.operation):\(request.commitHash):\(request.squashValidation?.count ?? -1):\(request.squashValidation?.message ?? "")")
            }
        ))
        #expect(requiredSquashProjectEvents == ["repo:squash:def456:3:combine"])
        var requiredHistoryCommandEvents: [String] = []
        #expect(CommitHistoryActionRules.performRequiredProjectHistoryCommand(
            project: Optional<String>.none,
            command: CommitHistoryActionRules.ProjectHistoryCommand<String, String>.revert(commit: "commit", commitHash: "abc123"),
            showUnavailable: { requiredHistoryCommandEvents.append("missing:\($0.isEmpty == false)") },
            perform: { _, project in requiredHistoryCommandEvents.append("project:\(project)") }
        ) == false)
        #expect(CommitHistoryActionRules.performRequiredProjectHistoryCommand(
            project: Optional("repo"),
            command: CommitHistoryActionRules.ProjectHistoryCommand<String, String>.reset(
                commit: "commit",
                commitHash: "def456",
                mode: "mixed",
                modeName: "mixed"
            ),
            showUnavailable: { requiredHistoryCommandEvents.append("missing:\($0)") },
            perform: { request, project in
                if case let .reset(commit, commitHash, mode, modeName) = request.command {
                    requiredHistoryCommandEvents.append("\(project):\(commit):\(commitHash):\(mode):\(modeName)")
                }
            }
        ))
        #expect(requiredHistoryCommandEvents == ["missing:true", "repo:commit:def456:mixed:mixed"])
        var requiredUndoProjectEvents: [String] = []
        #expect(CommitHistoryActionRules.performRequiredProjectUndoOperation(
            project: Optional<String>.none,
            projectPath: { $0 },
            commitHash: "abc123",
            parentHashes: ["parent"],
            showUnavailable: { requiredUndoProjectEvents.append("missing:\($0.isEmpty == false)") },
            perform: { request in
                requiredUndoProjectEvents.append("\(request.projectPath):\(request.commitHash):\(request.parentHashes.joined(separator: ","))")
            }
        ) == false)
        #expect(CommitHistoryActionRules.performRequiredProjectUndoOperation(
            project: Optional("/repo"),
            projectPath: { $0 },
            commitHash: "abc123",
            parentHashes: ["parent"],
            showUnavailable: { requiredUndoProjectEvents.append("missing:\($0)") },
            perform: { request in
                requiredUndoProjectEvents.append("\(request.projectPath):\(request.commitHash):\(request.parentHashes.joined(separator: ","))")
            }
        ))
        #expect(CommitHistoryActionRules.performRequiredProjectUndoOperation(
            project: Optional("/repo"),
            projectPath: { $0 },
            commitHash: "def456",
            parentHashes: ["base"],
            showUnavailable: { requiredUndoProjectEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredUndoProjectEvents.append("\(project):\(request.projectPath):\(request.commitHash):\(request.parentHashes.joined(separator: ","))")
            }
        ))
        #expect(requiredUndoProjectEvents == ["missing:true", "/repo:abc123:parent", "/repo:/repo:def456:base"])
        #expect(CommitHistoryActionRules.undoInitialCommitUnsupportedMessage().isEmpty == false)
        #expect(CommitHistoryActionRules.squashMessageRequiredMessage().isEmpty == false)
        #expect(CommitHistoryActionRules.revertedMessage(hash: "1234567890").contains("12345678"))
        #expect(CommitHistoryActionRules.resetMessage(hash: "1234567890", mode: "mixed").contains("mixed"))
        #expect(CommitHistoryActionRules.squashedMessage(count: 3).contains("3"))
        #expect(CommitHistoryActionRules.operationResult(
            for: .revert,
            succeeded: true,
            commitHash: "1234567890"
        ) == .init(
            completionState: CommitHistoryActionRules.completionState(for: .revert, succeeded: true),
            successMessage: CommitHistoryActionRules.revertedMessage(hash: "1234567890")
        ))
        #expect(CommitHistoryActionRules.operationResult(
            for: .reset,
            succeeded: true,
            commitHash: "1234567890",
            resetMode: "mixed"
        ).successMessage == CommitHistoryActionRules.resetMessage(hash: "1234567890", mode: "mixed"))
        #expect(CommitHistoryActionRules.operationResult(
            for: .squash,
            succeeded: true,
            commitHash: "1234567890",
            squashCount: 3
        ).successMessage == CommitHistoryActionRules.squashedMessage(count: 3))
        #expect(CommitHistoryActionRules.operationResult(
            for: .undo,
            succeeded: true,
            commitHash: "1234567890"
        ).successMessage == nil)
        #expect(CommitHistoryActionRules.operationResult(
            for: .revert,
            succeeded: false,
            commitHash: "1234567890"
        ).successMessage == nil)
        var historyCompletionEvents: [String] = []
        CommitHistoryActionRules.performCompletionState(
            CommitHistoryActionRules.completionState(for: .reset, succeeded: true),
            setRunningHistoryOperation: { historyCompletionEvents.append("running:\($0)") },
            setUndoing: { historyCompletionEvents.append("undoing:\($0)") },
            closeUndoConfirmation: { historyCompletionEvents.append("undo") },
            closeRevertConfirmation: { historyCompletionEvents.append("revert") },
            closeResetConfirmations: { historyCompletionEvents.append("reset") },
            closeSquashConfirmation: { historyCompletionEvents.append("squash") },
            clearSelectedCommit: { historyCompletionEvents.append("clear") }
        )
        CommitHistoryActionRules.performCompletionState(
            CommitHistoryActionRules.startState(for: .squash),
            setRunningHistoryOperation: { historyCompletionEvents.append("running:\($0)") },
            setUndoing: { historyCompletionEvents.append("undoing:\($0)") },
            closeUndoConfirmation: { historyCompletionEvents.append("undo") },
            closeRevertConfirmation: { historyCompletionEvents.append("revert") },
            closeResetConfirmations: { historyCompletionEvents.append("reset") },
            closeSquashConfirmation: { historyCompletionEvents.append("squash") },
            clearSelectedCommit: { historyCompletionEvents.append("clear") }
        )
        #expect(historyCompletionEvents == [
            "running:false",
            "undoing:false",
            "reset",
            "clear",
            "running:true",
            "undoing:false",
        ])
        var historyResultEvents: [String] = []
        CommitHistoryActionRules.performOperationResult(
            CommitHistoryActionRules.operationResult(
                for: .revert,
                succeeded: true,
                commitHash: "1234567890"
            ),
            applyCompletionState: { historyResultEvents.append("completion:\($0.closesRevertConfirmation)") },
            showSuccessMessage: { historyResultEvents.append("success:\($0.contains("12345678"))") }
        )
        CommitHistoryActionRules.performOperationResult(
            CommitHistoryActionRules.operationResult(
                for: .undo,
                succeeded: true,
                commitHash: "1234567890"
            ),
            applyCompletionState: { historyResultEvents.append("completion:\($0.closesUndoConfirmation)") },
            showSuccessMessage: { historyResultEvents.append("success:\($0)") }
        )
        #expect(historyResultEvents == ["completion:true", "success:true", "completion:true"])
        var historyOperationEvents: [String] = []
        await CommitHistoryActionRules.performHistoryOperation(
            operation: .reset,
            commitHash: "1234567890",
            resetMode: "mixed",
            perform: { historyOperationEvents.append("operation") },
            applyResult: { result in historyOperationEvents.append("result:\(result.successMessage?.contains("mixed") == true)") },
            handleFailure: { historyOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["operation", "result:true"])
        enum HistoryOperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "history failed"
            }
        }
        await CommitHistoryActionRules.performHistoryOperation(
            operation: .revert,
            commitHash: "1234567890",
            perform: { throw HistoryOperationError.failed },
            applyResult: { result in historyOperationEvents.append("result:\(result.successMessage == nil)") },
            handleFailure: { historyOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == [
            "operation",
            "result:true",
            "result:true",
            "failure:history failed",
        ])
        historyOperationEvents = []
        await CommitHistoryActionRules.performStartedHistoryOperation(
            operation: .reset,
            commitHash: "1234567890",
            resetMode: "hard",
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            perform: { historyOperationEvents.append("operation") },
            applyResult: { result in historyOperationEvents.append("result:\(result.successMessage?.contains("hard") == true)") },
            handleFailure: { historyOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["start:true", "operation", "result:true"])
        historyOperationEvents = []
        await CommitHistoryActionRules.performValidatedSquashOperation(
            validation: CommitHistoryActionRules.squashValidation(message: " ", commitIndex: 2),
            commitHash: "1234567890",
            showValidationFailure: { historyOperationEvents.append("validation:\($0.isEmpty == false)") },
            applyStartState: { historyOperationEvents.append("start:\($0.closesSquashConfirmation)") },
            perform: { validation in historyOperationEvents.append("operation:\(validation.count)") },
            applyResult: { result in historyOperationEvents.append("result:\(result.successMessage ?? "")") },
            handleFailure: { historyOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["validation:true"])
        historyOperationEvents = []
        await CommitHistoryActionRules.performValidatedSquashOperation(
            validation: CommitHistoryActionRules.squashValidation(message: "combine", commitIndex: 2),
            commitHash: "1234567890",
            showValidationFailure: { historyOperationEvents.append("validation:\($0)") },
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            perform: { validation in historyOperationEvents.append("operation:\(validation.count):\(validation.message)") },
            applyResult: { result in historyOperationEvents.append("result:\(result.successMessage?.contains("3") == true)") },
            handleFailure: { historyOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == [
            "start:true",
            "operation:3:combine",
            "result:true",
        ])
        var undoEvents: [String] = []
        await CommitHistoryActionRules.performUndoOperation(
            commitHash: "child",
            parentHashes: ["parent"],
            resetToParent: { undoEvents.append("reset:\($0)") },
            logSuccess: { undoEvents.append("log:\($0)") },
            postSuccess: { undoEvents.append("success:\($0.additionalInfo[CommitHistoryActionRules.parentHashInfoKey] ?? "")") },
            postFailure: { payload, error in undoEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyCompletionState: { undoEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { undoEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(undoEvents == ["reset:parent", "log:child", "success:parent", "completion:true"])
        undoEvents = []
        await CommitHistoryActionRules.performUndoOperation(
            commitHash: "initial",
            parentHashes: [],
            resetToParent: { undoEvents.append("reset:\($0)") },
            logSuccess: { undoEvents.append("log:\($0)") },
            postSuccess: { undoEvents.append("success:\($0.operation)") },
            postFailure: { payload, error in undoEvents.append("failure:\(payload.additionalInfo[CommitHistoryActionRules.commitHashInfoKey] ?? ""):\(error.localizedDescription.isEmpty == false)") },
            applyCompletionState: { undoEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { undoEvents.append("handle:\($0.localizedDescription.isEmpty == false)") }
        )
        #expect(undoEvents == ["failure:initial:true", "completion:false", "handle:true"])
        undoEvents = []
        await CommitHistoryActionRules.performStartedUndoOperation(
            commitHash: "child",
            parentHashes: ["parent"],
            applyStartState: { undoEvents.append("start:\($0.isUndoing)") },
            resetToParent: { undoEvents.append("reset:\($0)") },
            logSuccess: { undoEvents.append("log:\($0)") },
            postSuccess: { undoEvents.append("success:\($0.additionalInfo[CommitHistoryActionRules.parentHashInfoKey] ?? "")") },
            postFailure: { payload, error in undoEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyCompletionState: { undoEvents.append("completion:\($0.closesUndoConfirmation):\($0.clearsSelectedCommit)") },
            handleFailure: { undoEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(undoEvents == [
            "start:true",
            "reset:parent",
            "log:child",
            "success:parent",
            "completion:true:true",
        ])

        let commandHandlers = CommitHistoryActionRules.ProjectHistoryCommandHandlers<String, String>(
            undoCommit: { undoEvents.append("commandUndo:\($0)") },
            revertCommit: { historyOperationEvents.append("commandRevert:\($0)") },
            resetToCommit: { commit, mode in historyOperationEvents.append("commandReset:\(commit):\(mode)") },
            squashLastCommits: { validation in
                historyOperationEvents.append("commandSquash:\(validation.count):\(validation.message)")
            }
        )

        undoEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .undo(commit: "child", commitHash: "child", parentHashes: ["parent"]),
            handlers: commandHandlers,
            showValidationFailure: { undoEvents.append("validation:\($0)") },
            applyStartState: { undoEvents.append("start:\($0.isUndoing)") },
            logUndoSuccess: { undoEvents.append("log:\($0)") },
            postUndoSuccess: { undoEvents.append("success:\($0.additionalInfo[CommitHistoryActionRules.parentHashInfoKey] ?? "")") },
            postUndoFailure: { payload, error in undoEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { undoEvents.append("result:\($0.successMessage ?? "")") },
            applyCompletionState: { undoEvents.append("completion:\($0.closesUndoConfirmation)") },
            handleFailure: { undoEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(undoEvents == [
            "start:true",
            "commandUndo:child",
            "log:child",
            "success:parent",
            "completion:true",
        ])

        let projectCommandHandlers = CommitHistoryActionRules.ProjectHistoryProjectCommandHandlers<String, String, String>(
            undoCommit: { project, commit in undoEvents.append("projectCommandUndo:\(project):\(commit)") },
            revertCommit: { project, commit in historyOperationEvents.append("projectCommandRevert:\(project):\(commit)") },
            resetToCommit: { project, commit, mode in historyOperationEvents.append("projectCommandReset:\(project):\(commit):\(mode)") },
            squashLastCommits: { project, validation in
                historyOperationEvents.append("projectCommandSquash:\(project):\(validation.count):\(validation.message)")
            }
        )

        undoEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .undo(commit: "child", commitHash: "child", parentHashes: ["parent"]),
            project: "repo",
            handlers: projectCommandHandlers,
            showValidationFailure: { undoEvents.append("projectValidation:\($0)") },
            applyStartState: { undoEvents.append("projectStart:\($0.isUndoing)") },
            logUndoSuccess: { undoEvents.append("projectLog:\($0)") },
            postUndoSuccess: { undoEvents.append("projectSuccess:\($0.additionalInfo[CommitHistoryActionRules.parentHashInfoKey] ?? "")") },
            postUndoFailure: { payload, error in undoEvents.append("projectFailure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { undoEvents.append("projectResult:\($0.successMessage ?? "")") },
            applyCompletionState: { undoEvents.append("projectCompletion:\($0.closesUndoConfirmation)") },
            handleFailure: { undoEvents.append("projectHandle:\($0.localizedDescription)") }
        )
        #expect(undoEvents == [
            "projectStart:true",
            "projectCommandUndo:repo:child",
            "projectLog:child",
            "projectSuccess:parent",
            "projectCompletion:true",
        ])

        historyOperationEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .revert(commit: "abc123456", commitHash: "abc123456"),
            handlers: commandHandlers,
            showValidationFailure: { historyOperationEvents.append("validation:\($0)") },
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            logUndoSuccess: { historyOperationEvents.append("log:\($0)") },
            postUndoSuccess: { historyOperationEvents.append("success:\($0.operation)") },
            postUndoFailure: { payload, error in historyOperationEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { historyOperationEvents.append("result:\($0.successMessage?.contains("abc12345") == true)") },
            applyCompletionState: { historyOperationEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { historyOperationEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["start:true", "commandRevert:abc123456", "result:true"])

        historyOperationEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .reset(commit: "abc123456", commitHash: "abc123456", mode: "mixed", modeName: "mixed"),
            handlers: commandHandlers,
            showValidationFailure: { historyOperationEvents.append("validation:\($0)") },
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            logUndoSuccess: { historyOperationEvents.append("log:\($0)") },
            postUndoSuccess: { historyOperationEvents.append("success:\($0.operation)") },
            postUndoFailure: { payload, error in historyOperationEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { historyOperationEvents.append("result:\($0.successMessage?.contains("mixed") == true)") },
            applyCompletionState: { historyOperationEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { historyOperationEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["start:true", "commandReset:abc123456:mixed", "result:true"])

        historyOperationEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .squash(
                commitHash: "abc123456",
                validation: CommitHistoryActionRules.squashValidation(message: "combine", commitIndex: 1)
            ),
            handlers: commandHandlers,
            showValidationFailure: { historyOperationEvents.append("validation:\($0)") },
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            logUndoSuccess: { historyOperationEvents.append("log:\($0)") },
            postUndoSuccess: { historyOperationEvents.append("success:\($0.operation)") },
            postUndoFailure: { payload, error in historyOperationEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { historyOperationEvents.append("result:\($0.successMessage?.contains("2") == true)") },
            applyCompletionState: { historyOperationEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { historyOperationEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["start:true", "commandSquash:2:combine", "result:true"])

        historyOperationEvents = []
        await CommitHistoryActionRules.performProjectHistoryCommand(
            command: .squash(
                commitHash: "abc123456",
                validation: CommitHistoryActionRules.squashValidation(message: " ", commitIndex: 1)
            ),
            handlers: commandHandlers,
            showValidationFailure: { historyOperationEvents.append("validation:\($0.isEmpty == false)") },
            applyStartState: { historyOperationEvents.append("start:\($0.isRunningHistoryOperation)") },
            logUndoSuccess: { historyOperationEvents.append("log:\($0)") },
            postUndoSuccess: { historyOperationEvents.append("success:\($0.operation)") },
            postUndoFailure: { payload, error in historyOperationEvents.append("failure:\(payload.operation):\(error.localizedDescription)") },
            applyResult: { historyOperationEvents.append("result:\($0.successMessage ?? "")") },
            applyCompletionState: { historyOperationEvents.append("completion:\($0.clearsSelectedCommit)") },
            handleFailure: { historyOperationEvents.append("handle:\($0.localizedDescription)") }
        )
        #expect(historyOperationEvents == ["validation:true"])
    }

    @Test("commit row appearance rules prioritize selected state")
    func commitRowAppearanceRules() {
        #expect(CommitRowAppearanceRules.selectedOpacity == 0.1)
        #expect(CommitRowAppearanceRules.hoveredOpacity == 0.08)
        #expect(CommitRowAppearanceRules.hoverAnimationDuration == 0.15)
        #expect(CommitRowAppearanceRules.contentSpacing == 12.0)
        #expect(CommitRowAppearanceRules.logHashPrefixLength == 8)
        #expect(CommitRowAppearanceRules.logMessagePrefixLength == 30)
        #expect(CommitRowAppearanceRules.shortLogHash("1234567890") == "12345678")
        #expect(CommitRowAppearanceRules.shortLogMessage("abcdefghijklmnopqrstuvwxyz1234567890") == "abcdefghijklmnopqrstuvwxyz1234")
        #expect(CommitRowAppearanceRules.commitSelectionLogMessage(
            hash: "1234567890",
            message: "abcdefghijklmnopqrstuvwxyz1234567890"
        ).contains("12345678"))
        #expect(CommitRowAppearanceRules.pushStartLogMessage(hash: "1234567890").contains("12345678"))
        #expect(CommitRowAppearanceRules.pushSuccessLogMessage(hash: "1234567890").contains("12345678"))
        #expect(CommitRowAppearanceRules.undoSuccessLogMessage(hash: "1234567890") == "✅ Commit undone: 12345678")
        #expect(CommitRowAppearanceRules.avatarLoadStartLogMessage(hash: "1234567890") == "👤 Loading avatar users for commit: 12345678")
        #expect(CommitRowAppearanceRules.coAuthorsParsedLogMessage(hash: "1234567890", count: 2) == "👥 Parsed co-authors for commit 12345678: 2 authors")
        #expect(CommitRowAppearanceRules.commitSuccessReloadTagLogMessage(hash: "1234567890") == "✨ Git commit success - reloading tag for commit: 12345678")
        #expect(CommitRowAppearanceRules.backgroundState(isSelected: true, isHovered: true) == .selected)
        #expect(CommitRowAppearanceRules.backgroundState(isSelected: false, isHovered: true) == .hovered)
        #expect(CommitRowAppearanceRules.backgroundState(isSelected: false, isHovered: false) == .clear)
        #expect(CommitRowAppearanceRules.isSelected(currentCommitID: "head", rowCommitID: "head"))
        #expect(CommitRowAppearanceRules.isSelected(currentCommitID: nil, rowCommitID: "head") == false)
        #expect(CommitRowAppearanceRules.isSelected(currentCommitID: "other", rowCommitID: "head") == false)
        var selectedCommit = ""
        CommitRowAppearanceRules.performCommitSelection("head") {
            selectedCommit = $0
        }
        #expect(selectedCommit == "head")
        #expect(CommitRowAppearanceRules.presentationState(
            isFirstCommit: true,
            commitIndex: 0,
            isUnpushed: true,
            tag: "",
            commitTagCount: 0,
            parentHashCount: 1
        ) == .init(
            isUnpushed: true,
            hasTag: false,
            canUndo: true,
            canSquashThroughHead: false
        ))
        #expect(CommitRowAppearanceRules.presentationState(
            isFirstCommit: false,
            commitIndex: 2,
            isUnpushed: true,
            tag: "v1",
            commitTagCount: 1,
            parentHashCount: 1
        ) == .init(
            isUnpushed: true,
            hasTag: true,
            canUndo: false,
            canSquashThroughHead: true
        ))
    }

    @Test("commit tag rules normalize inputs and hash")
    func commitTagRules() async throws {
        #expect(CommitTagRules.normalizedTagName("  v1.0.0\n") == "v1.0.0")
        #expect(CommitTagRules.normalizedTagMessage("\n release \t") == "release")
        #expect(CommitTagRules.visibleTag(from: ["v1", "v2"]) == "v1")
        #expect(CommitTagRules.visibleTag(from: []) == "")
        #expect(CommitTagRules.createLightweightPromptState() == .init(
            showsPrompt: true,
            tagName: "",
            tagMessage: ""
        ))
        #expect(CommitTagRules.createAnnotatedPromptState() == .init(
            showsPrompt: true,
            tagName: "",
            tagMessage: ""
        ))
        #expect(CommitTagRules.promptState(for: .lightweight) == CommitTagRules.createLightweightPromptState())
        #expect(CommitTagRules.promptState(for: .annotated) == CommitTagRules.createAnnotatedPromptState())
        #expect(CommitTagRules.deleteLocalPromptState() == .init(showsPrompt: true))
        #expect(CommitTagRules.deleteRemotePromptState() == .init(showsPrompt: true))
        var tagPrompts: [String] = []
        CommitTagRules.performDeleteLocalPrompt { tagPrompts.append("local:\($0)") }
        CommitTagRules.performDeleteRemotePrompt { tagPrompts.append("remote:\($0)") }
        #expect(tagPrompts == ["local:true", "remote:true"])
        var tagReloads: [String] = []
        CommitTagRules.performAppWillBecomeActiveReload {
            tagReloads.append("active")
        }
        CommitTagRules.performCommitSuccessReload {
            tagReloads.append("commit")
        }
        #expect(CommitTagRules.shouldReloadTag(for: .appWillBecomeActive))
        #expect(CommitTagRules.shouldReloadTag(for: .commitSuccess))
        #expect(CommitTagRules.shouldReloadTag(for: .refsChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        )))
        #expect(CommitTagRules.shouldReloadTag(for: .refsChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other"
        )) == false)
        #expect(CommitTagRules.performReloadEvent(.appWillBecomeActive) {
            tagReloads.append("event-active")
        })
        #expect(CommitTagRules.performReloadEvent(.commitSuccess) {
            tagReloads.append("event-commit")
        })
        #expect(CommitTagRules.performReloadEvent(.refsChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other"
        )) {
            tagReloads.append("event-other")
        } == false)
        #expect(CommitTagRules.performReloadEvent(.refsChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        )) {
            tagReloads.append("event-refs")
        })
        #expect(tagReloads == ["active", "commit", "event-active", "event-commit", "event-refs"])
        #expect(CommitTagRules.promptApplicationState(
            state: .init(showsPrompt: true, tagName: "v1", tagMessage: ""),
            prompt: .lightweight
        ) == .init(
            lightweightTagName: "v1",
            annotatedTagName: nil,
            annotatedTagMessage: nil,
            showsLightweightPrompt: true,
            showsAnnotatedPrompt: false
        ))
        #expect(CommitTagRules.promptApplicationState(
            state: .init(showsPrompt: true, tagName: "v2", tagMessage: "release"),
            prompt: .annotated
        ) == .init(
            lightweightTagName: nil,
            annotatedTagName: "v2",
            annotatedTagMessage: "release",
            showsLightweightPrompt: false,
            showsAnnotatedPrompt: true
        ))
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(isCurrentProject: true))
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(isCurrentProject: false) == false)
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(eventProjectPath: "/repo", currentProjectPath: "/repo"))
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(eventProjectPath: "/repo", currentProjectPath: "/other") == false)
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ))
        #expect(CommitTagRules.shouldReloadTagOnRefsChanged(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 }
        ) == false)
        var refsChangedReloads = 0
        #expect(CommitTagRules.performRefsChangedReload(
            eventProjectPath: "/repo",
            currentProjectPath: "/other",
            reloadTag: { refsChangedReloads += 1 }
        ) == false)
        #expect(CommitTagRules.performRefsChangedReload(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            reloadTag: { refsChangedReloads += 1 }
        ))
        #expect(CommitTagRules.performRefsChangedReload(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            reloadTag: { refsChangedReloads += 1 }
        ))
        #expect(CommitTagRules.performRefsChangedReload(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 },
            reloadTag: { refsChangedReloads += 1 }
        ) == false)
        #expect(CommitTagRules.performRefsChangedReloadEvent(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            reloadTag: { refsChangedReloads += 1 }
        ))
        #expect(CommitTagRules.performRefsChangedReloadEvent(
            eventProjectPath: "/repo",
            currentProject: Optional("/other"),
            currentProjectPath: { $0 },
            reloadTag: { refsChangedReloads += 1 }
        ) == false)
        #expect(refsChangedReloads == 3)
        #expect(CommitTagRules.canCreateLightweightTag(name: " v1 "))
        #expect(CommitTagRules.canCreateLightweightTag(name: "   ") == false)
        #expect(CommitTagRules.canCreateAnnotatedTag(name: "v1", message: "release"))
        #expect(CommitTagRules.canCreateAnnotatedTag(name: "v1", message: "  ") == false)
        #expect(CommitTagRules.tagNameValidation(" v1 ") == .init(
            normalizedName: "v1",
            errorMessage: nil
        ))
        #expect(CommitTagRules.tagNameValidation(" \n ").canProceed == false)
        #expect(CommitTagRules.tagNameValidation(" \n ").errorMessage?.isEmpty == false)
        #expect(CommitTagRules.annotatedTagValidation(name: " v1 ", message: " release ") == .init(
            normalizedName: "v1",
            normalizedMessage: "release",
            errorMessage: nil
        ))
        #expect(CommitTagRules.annotatedTagValidation(name: " ", message: " release ").canProceed == false)
        #expect(CommitTagRules.annotatedTagValidation(name: "v1", message: " ").canProceed == false)
        #expect(CommitTagRules.createLightweightRequest(name: " v1 ") == .init(
            operation: .createLightweight,
            tagName: "v1",
            tagMessage: nil,
            errorMessage: nil,
            startState: CommitTagRules.startState(for: .createLightweight),
            successMessage: CommitTagRules.createdMessage(tagName: "v1")
        ))
        #expect(CommitTagRules.createAnnotatedRequest(name: " v1 ", message: " release ") == .init(
            operation: .createAnnotated,
            tagName: "v1",
            tagMessage: "release",
            errorMessage: nil,
            startState: CommitTagRules.startState(for: .createAnnotated),
            successMessage: CommitTagRules.createdMessage(tagName: "v1")
        ))
        #expect(CommitTagRules.tagRequest(for: .createLightweight, tagName: " v1 ") == CommitTagRules.createLightweightRequest(name: " v1 "))
        #expect(CommitTagRules.tagRequest(
            for: .createAnnotated,
            tagName: " v1 ",
            tagMessage: " release "
        ) == CommitTagRules.createAnnotatedRequest(name: " v1 ", message: " release "))
        #expect(CommitTagRules.createAnnotatedRequest(name: "v1", message: " ").canPerform == false)
        #expect(CommitTagRules.validationFailureMessage(
            for: CommitTagRules.createLightweightRequest(name: " ")
        ) == CommitTagRules.tagNameRequiredMessage())
        #expect(CommitTagRules.validationFailureMessage(
            for: CommitTagRules.createAnnotatedRequest(name: "v1", message: " ")
        ) == CommitTagRules.tagMessageRequiredMessage())
        #expect(CommitTagRules.validationFailureMessage(
            for: CommitTagRules.createLightweightRequest(name: "v1")
        ) == nil)
        var tagValidationFailures: [String] = []
        var tagStartStates: [CommitTagRules.CompletionState] = []
        #expect(CommitTagRules.performValidatedRequest(
            CommitTagRules.createLightweightRequest(name: " "),
            showValidationFailure: { tagValidationFailures.append($0) },
            applyStartState: { tagStartStates.append($0) }
        ) == false)
        #expect(tagValidationFailures == [CommitTagRules.tagNameRequiredMessage()])
        #expect(tagStartStates.isEmpty)
        #expect(CommitTagRules.performValidatedRequest(
            CommitTagRules.pushRequest(tagName: "v1"),
            showValidationFailure: { tagValidationFailures.append($0) },
            applyStartState: { tagStartStates.append($0) }
        ))
        #expect(tagStartStates == [CommitTagRules.startState(for: .push)])
        #expect(CommitTagRules.deleteLocalRequest(tagName: " v1 ").successMessage == CommitTagRules.deletedMessage(tagName: "v1"))
        #expect(CommitTagRules.pushRequest(tagName: " v1 ").successMessage == CommitTagRules.pushedMessage(tagName: "v1"))
        #expect(CommitTagRules.deleteRemoteRequest(tagName: " v1 ").successMessage == CommitTagRules.remoteDeletedMessage(tagName: "v1"))
        var projectTagEvents: [String] = []
        let projectTagHandlers = CommitTagRules.ProjectTagCommandHandlers<String>(
            createLightweight: { project, tagName, commitHash in projectTagEvents.append("light:\(project):\(tagName):\(commitHash)") },
            createAnnotated: { project, tagName, commitHash, message in projectTagEvents.append("annotated:\(project):\(tagName):\(commitHash):\(message)") },
            deleteLocal: { project, tagName in projectTagEvents.append("delete:\(project):\(tagName)") },
            push: { project, tagName in projectTagEvents.append("push:\(project):\(tagName)") },
            deleteRemote: { project, tagName in projectTagEvents.append("remote:\(project):\(tagName)") }
        )
        try await CommitTagRules.performProjectTagCommand(
            project: "repo",
            request: CommitTagRules.createLightweightRequest(name: "v1"),
            commitHash: "abc123",
            handlers: projectTagHandlers
        )
        try await CommitTagRules.performProjectTagCommand(
            project: "repo",
            request: CommitTagRules.createAnnotatedRequest(name: "v2", message: "release"),
            commitHash: "def456",
            handlers: projectTagHandlers
        )
        try await CommitTagRules.performProjectTagCommand(
            project: "repo",
            request: CommitTagRules.deleteLocalRequest(tagName: "v1"),
            commitHash: "ignored",
            handlers: projectTagHandlers
        )
        try await CommitTagRules.performProjectTagCommand(
            project: "repo",
            request: CommitTagRules.pushRequest(tagName: "v1"),
            commitHash: "ignored",
            handlers: projectTagHandlers
        )
        try await CommitTagRules.performProjectTagCommand(
            project: "repo",
            request: CommitTagRules.deleteRemoteRequest(tagName: "v1"),
            commitHash: "ignored",
            handlers: projectTagHandlers
        )
        #expect(projectTagEvents == [
            "light:repo:v1:abc123",
            "annotated:repo:v2:def456:release",
            "delete:repo:v1",
            "push:repo:v1",
            "remote:repo:v1",
        ])
        #expect(CommitTagRules.tagNameRequiredMessage().isEmpty == false)
        #expect(CommitTagRules.tagMessageRequiredMessage().isEmpty == false)
        #expect(CommitTagRules.createdMessage(tagName: "v1").contains("v1"))
        #expect(CommitTagRules.deletedMessage(tagName: "v1").contains("v1"))
        #expect(CommitTagRules.pushedMessage(tagName: "v1").contains("v1"))
        #expect(CommitTagRules.remoteDeletedMessage(tagName: "v1").contains("v1"))
        #expect(CommitTagRules.shortHash("1234567890abcdef") == "12345678")
        #expect(CommitTagRules.shortHash("abc", length: 8) == "abc")
        #expect(CommitTagRules.shortHash("abc", length: -1) == "")

        let lightweightSuccess = CommitTagRules.completionState(for: .createLightweight, succeeded: true)
        #expect(lightweightSuccess.clearsLightweightTagName)
        #expect(lightweightSuccess.closesCreateTagAlert)
        #expect(lightweightSuccess.reloadsTag)
        #expect(CommitTagRules.startState(for: .createLightweight).isCreatingTag)
        #expect(CommitTagRules.startState(for: .createLightweight).isCreatingAnnotatedTag == false)

        let annotatedSuccess = CommitTagRules.completionState(for: .createAnnotated, succeeded: true)
        #expect(annotatedSuccess.clearsAnnotatedTagFields)
        #expect(annotatedSuccess.closesCreateAnnotatedTagAlert)
        #expect(annotatedSuccess.reloadsTag)
        #expect(CommitTagRules.startState(for: .createAnnotated).isCreatingAnnotatedTag)

        let deleteLocalSuccess = CommitTagRules.completionState(for: .deleteLocal, succeeded: true)
        #expect(deleteLocalSuccess.closesDeleteTagConfirmation)
        #expect(deleteLocalSuccess.reloadsTag)
        #expect(CommitTagRules.startState(for: .deleteLocal).isDeletingTag)

        let pushFailure = CommitTagRules.completionState(for: .push, succeeded: false)
        #expect(pushFailure.isPushingTag == false)
        #expect(pushFailure.reloadsTag == false)
        #expect(pushFailure.closesDeleteRemoteTagConfirmation == false)
        #expect(CommitTagRules.startState(for: .push).isPushingTag)
        let pushRequest = CommitTagRules.pushRequest(tagName: " v1 ")
        #expect(CommitTagRules.operationResult(request: pushRequest, succeeded: true) == .init(
            completionState: CommitTagRules.completionState(for: .push, succeeded: true),
            successMessage: CommitTagRules.pushedMessage(tagName: "v1")
        ))
        #expect(CommitTagRules.operationResult(request: pushRequest, succeeded: false) == .init(
            completionState: CommitTagRules.completionState(for: .push, succeeded: false),
            successMessage: nil
        ))
        var promptEvents: [String] = []
        CommitTagRules.performPromptApplicationState(
            CommitTagRules.promptApplicationState(
                state: CommitTagRules.promptState(for: .lightweight),
                prompt: .lightweight
            ),
            setLightweightTagName: { promptEvents.append("lightweight:\($0)") },
            setAnnotatedTagName: { promptEvents.append("annotated-name:\($0)") },
            setAnnotatedTagMessage: { promptEvents.append("annotated-message:\($0)") },
            setLightweightPromptPresented: { promptEvents.append("show-lightweight:\($0)") },
            setAnnotatedPromptPresented: { promptEvents.append("show-annotated:\($0)") }
        )
        CommitTagRules.performPromptApplicationState(
            CommitTagRules.promptApplicationState(
                state: CommitTagRules.promptState(for: .annotated),
                prompt: .annotated
            ),
            setLightweightTagName: { promptEvents.append("lightweight:\($0)") },
            setAnnotatedTagName: { promptEvents.append("annotated-name:\($0)") },
            setAnnotatedTagMessage: { promptEvents.append("annotated-message:\($0)") },
            setLightweightPromptPresented: { promptEvents.append("show-lightweight:\($0)") },
            setAnnotatedPromptPresented: { promptEvents.append("show-annotated:\($0)") }
        )
        #expect(promptEvents == [
            "lightweight:",
            "show-lightweight:true",
            "annotated-name:",
            "annotated-message:",
            "show-annotated:true",
        ])

        let deleteRemoteSuccess = CommitTagRules.completionState(for: .deleteRemote, succeeded: true)
        #expect(deleteRemoteSuccess.isDeletingRemoteTag == false)
        #expect(deleteRemoteSuccess.closesDeleteRemoteTagConfirmation)
        #expect(deleteRemoteSuccess.reloadsTag == false)
        #expect(CommitTagRules.startState(for: .deleteRemote).isDeletingRemoteTag)
        var tagCompletionEvents: [String] = []
        CommitTagRules.performCompletionState(
            CommitTagRules.completionState(for: .createAnnotated, succeeded: true),
            setCreatingTag: { tagCompletionEvents.append("creating:\($0)") },
            setCreatingAnnotatedTag: { tagCompletionEvents.append("annotated:\($0)") },
            setDeletingTag: { tagCompletionEvents.append("deleting:\($0)") },
            setDeletingRemoteTag: { tagCompletionEvents.append("remote:\($0)") },
            setPushingTag: { tagCompletionEvents.append("pushing:\($0)") },
            clearLightweightTagName: { tagCompletionEvents.append("clear-lightweight") },
            clearAnnotatedTagFields: { tagCompletionEvents.append("clear-annotated") },
            closeCreateTagAlert: { tagCompletionEvents.append("close-lightweight") },
            closeCreateAnnotatedTagAlert: { tagCompletionEvents.append("close-annotated") },
            closeDeleteTagConfirmation: { tagCompletionEvents.append("close-delete") },
            closeDeleteRemoteTagConfirmation: { tagCompletionEvents.append("close-remote-delete") },
            reloadTag: { tagCompletionEvents.append("reload") }
        )
        CommitTagRules.performCompletionState(
            CommitTagRules.completionState(for: .push, succeeded: false),
            setCreatingTag: { tagCompletionEvents.append("creating:\($0)") },
            setCreatingAnnotatedTag: { tagCompletionEvents.append("annotated:\($0)") },
            setDeletingTag: { tagCompletionEvents.append("deleting:\($0)") },
            setDeletingRemoteTag: { tagCompletionEvents.append("remote:\($0)") },
            setPushingTag: { tagCompletionEvents.append("pushing:\($0)") },
            clearLightweightTagName: { tagCompletionEvents.append("clear-lightweight") },
            clearAnnotatedTagFields: { tagCompletionEvents.append("clear-annotated") },
            closeCreateTagAlert: { tagCompletionEvents.append("close-lightweight") },
            closeCreateAnnotatedTagAlert: { tagCompletionEvents.append("close-annotated") },
            closeDeleteTagConfirmation: { tagCompletionEvents.append("close-delete") },
            closeDeleteRemoteTagConfirmation: { tagCompletionEvents.append("close-remote-delete") },
            reloadTag: { tagCompletionEvents.append("reload") }
        )
        #expect(tagCompletionEvents == [
            "creating:false",
            "annotated:false",
            "deleting:false",
            "remote:false",
            "pushing:false",
            "clear-annotated",
            "close-annotated",
            "reload",
            "creating:false",
            "annotated:false",
            "deleting:false",
            "remote:false",
            "pushing:false",
        ])
        var tagResultEvents: [String] = []
        CommitTagRules.performOperationResult(
            CommitTagRules.operationResult(request: CommitTagRules.pushRequest(tagName: "v1"), succeeded: true),
            applyCompletionState: { tagResultEvents.append("completion:\($0.isPushingTag)") },
            showSuccessMessage: { tagResultEvents.append("success:\($0.contains("v1"))") }
        )
        CommitTagRules.performOperationResult(
            CommitTagRules.operationResult(request: CommitTagRules.pushRequest(tagName: "v1"), succeeded: false),
            applyCompletionState: { tagResultEvents.append("completion:\($0.isPushingTag)") },
            showSuccessMessage: { tagResultEvents.append("success:\($0)") }
        )
        #expect(tagResultEvents == ["completion:false", "success:true", "completion:false"])
        var tagOperationEvents: [String] = []
        await CommitTagRules.performTagOperation(
            request: CommitTagRules.createLightweightRequest(name: "v1"),
            operation: { request in tagOperationEvents.append("operation:\(request.tagName)") },
            applyResult: { result in tagOperationEvents.append("result:\(result.successMessage?.contains("v1") == true)") },
            handleFailure: { tagOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(tagOperationEvents == ["operation:v1", "result:true"])
        await CommitTagRules.performTagOperation(
            request: CommitTagRules.createLightweightRequest(name: " "),
            operation: { request in tagOperationEvents.append("operation:\(request.tagName)") },
            applyResult: { result in tagOperationEvents.append("result:\(result.successMessage ?? "")") },
            handleFailure: { tagOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(tagOperationEvents == ["operation:v1", "result:true"])
        enum TagOperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "tag failed"
            }
        }
        await CommitTagRules.performTagOperation(
            request: CommitTagRules.pushRequest(tagName: "v1"),
            operation: { _ in throw TagOperationError.failed },
            applyResult: { result in tagOperationEvents.append("result:\(result.successMessage == nil)") },
            handleFailure: { tagOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(tagOperationEvents == [
            "operation:v1",
            "result:true",
            "result:true",
            "failure:tag failed",
        ])
        var requiredTagProjectEvents: [String] = []
        #expect(CommitTagRules.performRequiredProjectTagRequest(
            project: Optional<String>.none,
            request: CommitTagRules.createLightweightRequest(name: "v1"),
            projectUnavailableMessage: "Project unavailable",
            showUnavailable: { requiredTagProjectEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredTagProjectEvents.append("\(project):\(request.operation):\(request.tagName)")
            }
        ) == false)
        #expect(CommitTagRules.performRequiredProjectTagRequest(
            project: Optional("repo"),
            request: CommitTagRules.createLightweightRequest(name: "v1"),
            projectUnavailableMessage: "Project unavailable",
            showUnavailable: { requiredTagProjectEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredTagProjectEvents.append("\(project):\(request.operation):\(request.tagName)")
            }
        ))
        #expect(CommitTagRules.performRequiredProjectTagRequest(
            project: Optional("repo"),
            operation: .createAnnotated,
            tagName: " v2 ",
            tagMessage: " release ",
            projectUnavailableMessage: "Project unavailable",
            showUnavailable: { requiredTagProjectEvents.append("missing:\($0)") },
            perform: { request, project in
                requiredTagProjectEvents.append("\(project):\(request.operation):\(request.tagName):\(request.tagMessage ?? "")")
            }
        ))
        #expect(requiredTagProjectEvents == [
            "missing:Project unavailable",
            "repo:createLightweight:v1",
            "repo:createAnnotated:v2:release",
        ])
        var requiredTagCommandEvents: [String] = []
        #expect(CommitTagRules.performRequiredProjectTagCommand(
            project: Optional<String>.none,
            operation: .push,
            tagName: "v1",
            commitHash: "abc123",
            projectUnavailableMessage: "Project unavailable",
            showUnavailable: { requiredTagCommandEvents.append("missing:\($0)") },
            perform: { command in
                requiredTagCommandEvents.append("\(command.project):\(command.request.operation):\(command.request.tagName):\(command.commitHash)")
            }
        ) == false)
        #expect(CommitTagRules.performRequiredProjectTagCommand(
            project: Optional("repo"),
            operation: .push,
            tagName: " v1 ",
            commitHash: "abc123",
            projectUnavailableMessage: "Project unavailable",
            showUnavailable: { requiredTagCommandEvents.append("missing:\($0)") },
            perform: { command in
                requiredTagCommandEvents.append("\(command.project):\(command.request.operation):\(command.request.tagName):\(command.commitHash)")
            }
        ))
        #expect(requiredTagCommandEvents == [
            "missing:Project unavailable",
            "repo:push:v1:abc123",
        ])
        tagOperationEvents = []
        await CommitTagRules.performValidatedTagOperation(
            request: CommitTagRules.createLightweightRequest(name: " "),
            showValidationFailure: { tagOperationEvents.append("validation:\($0.isEmpty == false)") },
            applyStartState: { tagOperationEvents.append("start:\($0.isCreatingTag)") },
            operation: { request in tagOperationEvents.append("operation:\(request.tagName)") },
            applyResult: { result in tagOperationEvents.append("result:\(result.successMessage ?? "")") },
            handleFailure: { tagOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(tagOperationEvents == ["validation:true"])
        tagOperationEvents = []
        await CommitTagRules.performValidatedTagOperation(
            request: CommitTagRules.pushRequest(tagName: "v1"),
            showValidationFailure: { tagOperationEvents.append("validation:\($0)") },
            applyStartState: { tagOperationEvents.append("start:\($0.isPushingTag)") },
            operation: { request in tagOperationEvents.append("operation:\(request.tagName)") },
            applyResult: { result in tagOperationEvents.append("result:\(result.successMessage?.contains("v1") == true)") },
            handleFailure: { tagOperationEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(tagOperationEvents == [
            "start:true",
            "operation:v1",
            "result:true",
        ])
        var loadedTags: [String] = []
        await CommitTagRules.performVisibleTagLoad(
            loadTags: { ["v1", "v2"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performVisibleTagLoad(
            loadTags: { [] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performVisibleTagLoad(
            loadTags: { throw TagOperationError.failed },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            loadTags: nil,
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            loadTags: { ["v2"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            commitHash: "abc123",
            loadTags: { hash in ["tag-\(hash)"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            commitHash: "def456",
            loadTags: nil,
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            commitHash: "ghi789",
            loadTags: { _ in throw TagOperationError.failed },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performProjectVisibleTagLoad(
            project: Optional("repo"),
            commitHash: "jkl012",
            loadTags: { project, hash in ["\(project)-\(hash)"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performProjectVisibleTagLoad(
            project: Optional<String>.none,
            commitHash: "mno345",
            loadTags: { project, hash in ["\(project)-\(hash)"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performProjectVisibleTagLoadCommand(
            project: Optional("repo"),
            commitHash: "pqr678",
            loadTags: { request in ["\(request.project)-\(request.commitHash)"] },
            setTag: { loadedTags.append($0) }
        )
        await CommitTagRules.performProjectVisibleTagLoadCommand(
            project: Optional<String>.none,
            commitHash: "stu901",
            loadTags: { request in ["\(request.project)-\(request.commitHash)"] },
            setTag: { loadedTags.append($0) }
        )
        #expect(loadedTags == ["v1", "", "", "", "v2", "tag-abc123", "", "", "repo-jkl012", "", "repo-pqr678", ""])
    }

    @Test("commit list pagination rules remain stable")
    func commitListPaginationRules() async throws {
        #expect(CommitListPaginationRules.initialPage == 0)
        #expect(CommitListPaginationRules.firstPageAfterRefresh == 1)
        #expect(CommitListPaginationRules.hasMoreAfterRefreshStart)
        #expect(CommitListPaginationRules.defaultPageSize == 50)
        #expect(CommitListPaginationRules.showCommitGraphStorageKey == "App.ShowCommitGraph")
        #expect(CommitListPaginationRules.gitHeadChangedEventInfoKey == "headChanged")
        #expect(CommitListPaginationRules.loadMoreScheduleDelay == 0.1)
        #expect(CommitListPaginationRules.restoreSelectionMaxLoadMoreAttempts == 3)
        #expect(CommitListPaginationRules.projectChangedRefreshReason == "Project Changed")
        #expect(CommitListPaginationRules.branchChangedRefreshReason == "Branch Changed")
        #expect(CommitListPaginationRules.commitSuccessRefreshReason == "GitCommitSuccess")
        #expect(CommitListPaginationRules.appearRefreshReason == "OnAppear")
        #expect(CommitListPaginationRules.pullSuccessRefreshReason == "GitPullSuccess")
        #expect(CommitListPaginationRules.gitDirectoryDidChangeRefreshReason == "GitDirectoryDidChange")
        #expect(CommitListPaginationRules.applicationWillBecomeActiveRefreshReason == "ApplicationWillBecomeActive")
        #expect(CommitListPaginationRules.duplicateLoadMoreWarningLogMessage() == "⚠️ LoadMoreCommits - all commits were duplicates!")
        #expect(CommitListPaginationRules.loadMoreFailureLogMessage(errorDescription: "boom") == "❌ LoadMoreCommits error: boom")
        #expect(CommitListPaginationRules.refreshLogMessage(reason: "Manual") == "🍋 Refresh(Manual)")
        #expect(CommitListPaginationRules.nextPageAfterAppending(currentPage: 3) == 4)
        #expect(CommitListPaginationRules.pageSize(currentPageSize: 50, viewportHeight: 310) == 50)
        #expect(CommitListPaginationRules.pageSize(currentPageSize: 10, viewportHeight: 310) == 15)
        #expect(CommitListPaginationRules.pageSize(currentPageSize: 10, viewportHeight: 310, rowHeight: 0) == 10)
        var appliedPageSize = 10
        CommitListPaginationRules.performGeometryAppear(
            currentPageSize: appliedPageSize,
            viewportHeight: 310,
            setPageSize: { appliedPageSize = $0 }
        )
        #expect(appliedPageSize == 15)
        var selectedCommit: String?
        CommitListPaginationRules.performCommitSelection(
            Optional("abc123"),
            select: { selectedCommit = $0 }
        )
        #expect(selectedCommit == "abc123")
        CommitListPaginationRules.performCommitSelection(
            Optional<String>.none,
            select: { selectedCommit = $0 }
        )
        #expect(selectedCommit == nil)
        var appearEvents: [String] = []
        CommitListPaginationRules.performAppear(
            refresh: { appearEvents.append("refresh") },
            restoreSelection: { appearEvents.append("restore") }
        )
        #expect(appearEvents == ["refresh", "restore"])
        #expect(CommitListPaginationRules.loadMoreThreshold(totalCount: 50) == 40)
        #expect(CommitListPaginationRules.loadMoreThreshold(totalCount: 8) == 6)
        #expect(CommitListPaginationRules.shouldScheduleLoadMore(
            appearedIndex: 40,
            totalCount: 50,
            hasMoreCommits: true,
            isLoading: false,
            isAlreadyScheduled: false
        ))
        #expect(CommitListPaginationRules.shouldScheduleLoadMore(
            appearedIndex: 39,
            totalCount: 50,
            hasMoreCommits: true,
            isLoading: false,
            isAlreadyScheduled: false
        ) == false)
        #expect(CommitListPaginationRules.loadMoreScheduleState(
            appearedIndex: 40,
            totalCount: 50,
            hasMoreCommits: true,
            isLoading: false,
            isAlreadyScheduled: false
        ) == .init(shouldSchedule: true, delay: CommitListPaginationRules.loadMoreScheduleDelay))
        #expect(CommitListPaginationRules.loadMoreScheduleState(
            appearedIndex: 40,
            totalCount: 50,
            hasMoreCommits: true,
            isLoading: true,
            isAlreadyScheduled: false
        ).shouldSchedule == false)
        var loadMoreScheduleEvents: [String] = []
        #expect(CommitListPaginationRules.performLoadMoreScheduleState(
            .init(shouldSchedule: false, delay: 0.25),
            setScheduled: { loadMoreScheduleEvents.append("scheduled:\($0)") },
            logScheduled: { loadMoreScheduleEvents.append("log-scheduled") },
            schedule: { delay, action in
                loadMoreScheduleEvents.append("delay:\(delay)")
                action()
            },
            logExecuting: { loadMoreScheduleEvents.append("log-executing") },
            loadMore: { loadMoreScheduleEvents.append("load-more") }
        ) == false)
        #expect(loadMoreScheduleEvents.isEmpty)
        #expect(CommitListPaginationRules.performLoadMoreScheduleState(
            .init(shouldSchedule: true, delay: 0.25),
            setScheduled: { loadMoreScheduleEvents.append("scheduled:\($0)") },
            logScheduled: { loadMoreScheduleEvents.append("log-scheduled") },
            schedule: { delay, action in
                loadMoreScheduleEvents.append("delay:\(delay)")
                action()
            },
            logExecuting: { loadMoreScheduleEvents.append("log-executing") },
            loadMore: { loadMoreScheduleEvents.append("load-more") }
        ))
        #expect(loadMoreScheduleEvents == [
            "scheduled:true",
            "log-scheduled",
            "delay:0.25",
            "scheduled:false",
            "log-executing",
            "load-more",
        ])
        #expect(CommitListPaginationRules.contentPresentationState(
            isLoading: true,
            commitCount: 0
        ) == .init(isInitialLoading: true, hasRows: false))
        #expect(CommitListPaginationRules.contentPresentationState(
            isLoading: true,
            commitCount: 2
        ) == .init(isInitialLoading: false, hasRows: true))
        #expect(CommitListPaginationRules.workspacePresentationState(
            project: Optional("repo"),
            isLoading: true,
            commitCount: 0
        ) == .init(
            hasProject: true,
            content: .init(isInitialLoading: true, hasRows: false)
        ))
        #expect(CommitListPaginationRules.workspacePresentationState(
            project: Optional<String>.none,
            isLoading: true,
            commitCount: 2
        ) == .init(
            hasProject: false,
            content: .init(isInitialLoading: false, hasRows: true)
        ))
        var appliedLoading: Bool?
        var appliedCurrentPage: Int?
        var appliedHasMoreCommits: Bool?
        CommitListPaginationRules.performPageState(
            .init(isLoading: true, currentPage: 3, hasMoreCommits: false),
            setLoading: { appliedLoading = $0 },
            setCurrentPage: { appliedCurrentPage = $0 },
            setHasMoreCommits: { appliedHasMoreCommits = $0 }
        )
        #expect(appliedLoading == true)
        #expect(appliedCurrentPage == 3)
        #expect(appliedHasMoreCommits == false)
        var requiredProjectEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProject(Optional<String>.none) {
            requiredProjectEvents.append($0)
        } == false)
        #expect(CommitListPaginationRules.performRequiredProject(Optional("repo")) {
            requiredProjectEvents.append($0)
        } == true)
        #expect(requiredProjectEvents == ["repo"])
        var requiredRefreshEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProjectRefresh(
            project: Optional<String>.none,
            reason: "Manual",
            perform: { request, project in
                requiredRefreshEvents.append("\(project):\(request.reason)")
            }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectRefresh(
            project: Optional("repo"),
            reason: "Manual",
            perform: { request, project in
                requiredRefreshEvents.append("\(project):\(request.reason)")
            }
        ))
        #expect(requiredRefreshEvents == ["repo:Manual"])
        var requiredRefreshCommandEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProjectRefreshCommand(
            project: Optional<String>.none,
            reason: "Manual",
            perform: { projectRequest in
                requiredRefreshCommandEvents.append("\(projectRequest.project):\(projectRequest.request.reason)")
            }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectRefreshCommand(
            project: Optional("repo"),
            reason: "Manual",
            perform: { projectRequest in
                requiredRefreshCommandEvents.append("\(projectRequest.project):\(projectRequest.request.reason)")
            }
        ))
        #expect(requiredRefreshCommandEvents == ["repo:Manual"])
        #expect(CommitListPaginationRules.firstCommitID(["head", "parent"]) == "head")
        #expect(CommitListPaginationRules.firstCommitID([]) == nil)
        #expect(CommitListPaginationRules.firstCommitID(
            in: [(hash: "head", index: 0), (hash: "parent", index: 1)],
            id: \.hash
        ) == "head")
        #expect(CommitListPaginationRules.refreshStartState() == .init(
            isLoading: true,
            currentPage: 0,
            hasMoreCommits: true
        ))
        #expect(CommitListPaginationRules.refreshSuccessState() == .init(
            isLoading: false,
            currentPage: 1,
            hasMoreCommits: true
        ))
        #expect(CommitListPaginationRules.refreshFailureState() == .init(
            isLoading: false,
            currentPage: 0,
            hasMoreCommits: true
        ))
        #expect(CommitListPaginationRules.refreshSuccessResultState(unpushedIDs: ["a", "b"]) == .init(
            pageState: CommitListPaginationRules.refreshSuccessState(),
            unpushedIDs: ["a", "b"],
            clearsCommits: false
        ))
        #expect(CommitListPaginationRules.refreshSuccessResultState(unpushedIDs: ["a", "b"]).unpushedCount == 2)
        #expect(CommitListPaginationRules.refreshFailureResultState() == .init(
            pageState: CommitListPaginationRules.refreshFailureState(),
            unpushedIDs: [],
            clearsCommits: true
        ))
        struct UnpushedFixture {
            let hash: String
        }
        let refreshLoadResult = try await CommitListPaginationRules.performRefreshLoad(
            pageSize: 25,
            loadItems: { page, limit in ["page:\(page)", "limit:\(limit)"] },
            loadUnpushedItems: { [UnpushedFixture(hash: "a"), UnpushedFixture(hash: "b")] },
            unpushedID: \.hash
        )
        #expect(refreshLoadResult.items == ["page:0", "limit:25"])
        #expect(refreshLoadResult.unpushedIDs == ["a", "b"])
        let refreshLoadHandlers = CommitListPaginationRules.RefreshLoadHandlers<String, UnpushedFixture>(
            loadItems: { page, limit in ["handler-page:\(page)", "handler-limit:\(limit)"] },
            loadUnpushedItems: { [UnpushedFixture(hash: "handler-a")] },
            unpushedID: \.hash
        )
        let handledRefreshLoadResult = try await CommitListPaginationRules.performRefreshLoad(
            pageSize: 30,
            handlers: refreshLoadHandlers
        )
        #expect(handledRefreshLoadResult.items == ["handler-page:0", "handler-limit:30"])
        #expect(handledRefreshLoadResult.unpushedIDs == ["handler-a"])
        var refreshedItems: [String] = []
        var refreshGraphRebuildCount = 0
        var refreshPageStates: [CommitListPaginationRules.PageState] = []
        var refreshUnpushedUpdates: [(count: Int, hashes: [String])] = []
        CommitListPaginationRules.performRefreshSuccessResultState(
            CommitListPaginationRules.refreshSuccessResultState(unpushedIDs: ["a", "b"]),
            items: ["head", "parent"],
            updateUnpushed: { refreshUnpushedUpdates.append((count: $0, hashes: $1)) },
            setItems: { refreshedItems = $0 },
            rebuildGraph: { refreshGraphRebuildCount += 1 },
            applyPageState: { refreshPageStates.append($0) }
        )
        #expect(refreshUnpushedUpdates.count == 1)
        #expect(refreshUnpushedUpdates[0].count == 2)
        #expect(refreshUnpushedUpdates[0].hashes == ["a", "b"])
        #expect(refreshedItems == ["head", "parent"])
        #expect(refreshGraphRebuildCount == 1)
        #expect(refreshPageStates == [CommitListPaginationRules.refreshSuccessState()])
        CommitListPaginationRules.performRefreshFailureResultState(
            CommitListPaginationRules.refreshFailureResultState(),
            setItems: { refreshedItems = $0 },
            rebuildGraph: { refreshGraphRebuildCount += 1 },
            applyPageState: { refreshPageStates.append($0) }
        )
        #expect(refreshedItems.isEmpty)
        #expect(refreshGraphRebuildCount == 2)
        #expect(refreshPageStates == [
            CommitListPaginationRules.refreshSuccessState(),
            CommitListPaginationRules.refreshFailureState(),
        ])
        var didCancelPreviousRefreshes = false
        CommitListPaginationRules.performRefreshStart(
            cancelPreviousRefreshes: {
                didCancelPreviousRefreshes = true
            },
            applyPageState: { refreshPageStates.append($0) }
        )
        #expect(didCancelPreviousRefreshes)
        #expect(refreshPageStates.last == CommitListPaginationRules.refreshStartState())
        var refreshOperationEvents: [String] = []
        await CommitListPaginationRules.performRefreshOperation(
            pageSize: 10,
            loadItems: { page, limit in
                refreshOperationEvents.append("load:\(page):\(limit)")
                return ["head"]
            },
            loadUnpushedItems: {
                refreshOperationEvents.append("load-unpushed")
                return [UnpushedFixture(hash: "head")]
            },
            unpushedID: \.hash,
            logRefresh: { refreshOperationEvents.append("log") },
            applySuccess: { items, state in
                refreshOperationEvents.append("success:\(items.joined(separator: ",")):\(state.unpushedCount)")
            },
            applyFailure: { state in
                refreshOperationEvents.append("failure:\(state.clearsCommits)")
            }
        )
        #expect(refreshOperationEvents == [
            "log",
            "load:0:10",
            "load-unpushed",
            "success:head:1",
        ])
        refreshOperationEvents = []
        await CommitListPaginationRules.performRefreshOperation(
            pageSize: 10,
            loadItems: { _, _ -> [String] in
                refreshOperationEvents.append("load")
                throw NSError(domain: "CommitListPaginationRulesTest", code: 1)
            },
            loadUnpushedItems: {
                refreshOperationEvents.append("load-unpushed")
                return [UnpushedFixture(hash: "head")]
            },
            unpushedID: \.hash,
            logRefresh: { refreshOperationEvents.append("log") },
            applySuccess: { items, state in
                refreshOperationEvents.append("success:\(items.count):\(state.unpushedCount)")
            },
            applyFailure: { state in
                refreshOperationEvents.append("failure:\(state.clearsCommits)")
            }
        )
        #expect(refreshOperationEvents == [
            "log",
            "load",
            "failure:true",
        ])
        refreshOperationEvents = []
        await CommitListPaginationRules.performRefreshOperation(
            pageSize: 20,
            handlers: CommitListPaginationRules.RefreshLoadHandlers<String, UnpushedFixture>(
                loadItems: { page, limit in
                    refreshOperationEvents.append("handler-load:\(page):\(limit)")
                    return ["handler-head"]
                },
                loadUnpushedItems: {
                    refreshOperationEvents.append("handler-load-unpushed")
                    return [UnpushedFixture(hash: "handler-head")]
                },
                unpushedID: \.hash
            ),
            logRefresh: { refreshOperationEvents.append("handler-log") },
            applySuccess: { items, state in
                refreshOperationEvents.append("handler-success:\(items.joined(separator: ",")):\(state.unpushedCount)")
            },
            applyFailure: { state in
                refreshOperationEvents.append("handler-failure:\(state.clearsCommits)")
            }
        )
        #expect(refreshOperationEvents == [
            "handler-log",
            "handler-load:0:20",
            "handler-load-unpushed",
            "handler-success:handler-head:1",
        ])
        refreshOperationEvents = []
        await CommitListPaginationRules.performRefreshOperation(
            request: CommitListPaginationRules.ProjectRefreshRequest(
                request: CommitListPaginationRules.RefreshRequest(reason: "project-refresh"),
                project: "repo"
            ),
            pageSize: 35,
            handlers: CommitListPaginationRules.ProjectRefreshLoadHandlers<String, String, UnpushedFixture>(
                loadItems: { project, page, limit in
                    refreshOperationEvents.append("project-load:\(project):\(page):\(limit)")
                    return ["project-head"]
                },
                loadUnpushedItems: { project in
                    refreshOperationEvents.append("project-load-unpushed:\(project)")
                    return [UnpushedFixture(hash: "project-head")]
                },
                unpushedID: \.hash
            ),
            logRefresh: { refreshOperationEvents.append("project-log") },
            applySuccess: { items, state in
                refreshOperationEvents.append("project-success:\(items.joined(separator: ",")):\(state.unpushedCount)")
            },
            applyFailure: { state in
                refreshOperationEvents.append("project-failure:\(state.clearsCommits)")
            }
        )
        #expect(refreshOperationEvents == [
            "project-log",
            "project-load:repo:0:35",
            "project-load-unpushed:repo",
            "project-success:project-head:1",
        ])
        #expect(CommitListPaginationRules.loadingState(
            currentPage: 3,
            hasMoreCommits: true
        ) == .init(isLoading: true, currentPage: 3, hasMoreCommits: true))
        var loadMoreFailureStates: [CommitListPaginationRules.PageState] = []
        CommitListPaginationRules.performLoadMoreFailure(
            currentPage: 3,
            hasMoreCommits: false,
            applyPageState: { loadMoreFailureStates.append($0) }
        )
        #expect(loadMoreFailureStates == [.init(
            isLoading: false,
            currentPage: 3,
            hasMoreCommits: false
        )])
        #expect(CommitListPaginationRules.loadMoreRequestState(
            isLoading: false,
            hasMoreCommits: true,
            currentPage: 3
        ) == .init(
            canRequest: true,
            pageState: CommitListPaginationRules.loadingState(currentPage: 3, hasMoreCommits: true)
        ))
        #expect(CommitListPaginationRules.loadMoreRequestState(
            isLoading: true,
            hasMoreCommits: true,
            currentPage: 3
        ).canRequest == false)
        #expect(CommitListPaginationRules.loadMoreRequestState(
            isLoading: false,
            hasMoreCommits: true,
            currentPage: 3,
            remainingAttempts: 0
        ).canRequest == false)
        var loadMorePageStates: [CommitListPaginationRules.PageState] = []
        #expect(CommitListPaginationRules.performLoadMoreRequestState(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: true,
                hasMoreCommits: true,
                currentPage: 3
            ),
            applyPageState: { loadMorePageStates.append($0) }
        ) == false)
        #expect(loadMorePageStates.isEmpty)
        #expect(CommitListPaginationRules.performLoadMoreRequestState(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: false,
                hasMoreCommits: true,
                currentPage: 3
            ),
            applyPageState: { loadMorePageStates.append($0) }
        ))
        #expect(loadMorePageStates == [
            CommitListPaginationRules.loadingState(currentPage: 3, hasMoreCommits: true)
        ])
        var requiredLoadMoreEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreRequest(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: false,
                hasMoreCommits: true,
                currentPage: 3
            ),
            project: Optional<String>.none,
            applyPageState: { requiredLoadMoreEvents.append("page:\($0.currentPage)") },
            perform: { requiredLoadMoreEvents.append("project:\($0)") }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreRequest(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: true,
                hasMoreCommits: true,
                currentPage: 3
            ),
            project: Optional("repo"),
            applyPageState: { requiredLoadMoreEvents.append("page:\($0.currentPage)") },
            perform: { requiredLoadMoreEvents.append("project:\($0)") }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreRequest(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: false,
                hasMoreCommits: true,
                currentPage: 3
            ),
            project: Optional("repo"),
            applyPageState: { requiredLoadMoreEvents.append("page:\($0.currentPage)") },
            perform: { requiredLoadMoreEvents.append("project:\($0)") }
        ))
        #expect(requiredLoadMoreEvents == ["page:3", "project:repo"])
        var requiredLoadMoreCommandEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreCommand(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: false,
                hasMoreCommits: true,
                currentPage: 4
            ),
            project: Optional<String>.none,
            applyPageState: { requiredLoadMoreCommandEvents.append("page:\($0.currentPage)") },
            perform: { request in
                requiredLoadMoreCommandEvents.append("project:\(request.project):\(request.state.pageState.currentPage)")
            }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreCommand(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: true,
                hasMoreCommits: true,
                currentPage: 4
            ),
            project: Optional("repo"),
            applyPageState: { requiredLoadMoreCommandEvents.append("page:\($0.currentPage)") },
            perform: { request in
                requiredLoadMoreCommandEvents.append("project:\(request.project):\(request.state.pageState.currentPage)")
            }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectLoadMoreCommand(
            CommitListPaginationRules.loadMoreRequestState(
                isLoading: false,
                hasMoreCommits: true,
                currentPage: 4
            ),
            project: Optional("repo"),
            applyPageState: { requiredLoadMoreCommandEvents.append("page:\($0.currentPage)") },
            perform: { request in
                requiredLoadMoreCommandEvents.append("project:\(request.project):\(request.state.pageState.currentPage)")
            }
        ))
        #expect(requiredLoadMoreCommandEvents == ["page:4", "project:repo:4"])
        #expect(try await CommitListPaginationRules.performLoadMoreLoad(
            page: 3,
            pageSize: 25,
            loadItems: { page, limit in ["page:\(page)", "limit:\(limit)"] }
        ) == ["page:3", "limit:25"])
        let loadMoreHandlers = CommitListPaginationRules.LoadMoreHandlers<String>(
            loadItems: { page, limit in ["handler-page:\(page)", "handler-limit:\(limit)"] },
            id: { $0 }
        )
        #expect(try await CommitListPaginationRules.performLoadMoreLoad(
            page: 4,
            pageSize: 30,
            handlers: loadMoreHandlers
        ) == ["handler-page:4", "handler-limit:30"])
        var loadMoreOperationEvents: [String] = []
        await CommitListPaginationRules.performLoadMoreOperation(
            page: 2,
            pageSize: 25,
            existingItems: ["a", "b"],
            currentPage: 2,
            hasMoreCommits: true,
            loadItems: { page, limit in
                loadMoreOperationEvents.append("load:\(page):\(limit)")
                return ["b", "c"]
            },
            id: { $0 },
            applyAppend: { newItems, state in
                loadMoreOperationEvents.append("append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ","))")
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("failure:\(state.currentPage):\(state.hasMoreCommits)")
            },
            logFailure: { error in
                loadMoreOperationEvents.append("log:\(error.localizedDescription)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "load:2:25",
            "append:b,c:c",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performLoadMoreOperation(
            page: 4,
            pageSize: 30,
            existingItems: ["a"],
            currentPage: 4,
            hasMoreCommits: true,
            handlers: CommitListPaginationRules.LoadMoreHandlers<String>(
                loadItems: { page, limit in
                    loadMoreOperationEvents.append("handler-load:\(page):\(limit)")
                    return ["a", "d"]
                },
                id: { $0 }
            ),
            applyAppend: { newItems, state in
                loadMoreOperationEvents.append("handler-append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ","))")
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("handler-failure:\(state.currentPage):\(state.hasMoreCommits)")
            },
            logFailure: { error in
                loadMoreOperationEvents.append("handler-log:\(error.localizedDescription)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "handler-load:4:30",
            "handler-append:a,d:d",
        ])
        loadMoreOperationEvents = []
        let projectLoadMoreHandlers = CommitListPaginationRules.ProjectLoadMoreHandlers<String, String>(
            loadItems: { project, page, limit in
                loadMoreOperationEvents.append("project-load:\(project):\(page):\(limit)")
                return ["a", "\(project)-\(page)-\(limit)"]
            },
            id: { $0 }
        )
        await CommitListPaginationRules.performLoadMoreOperation(
            request: CommitListPaginationRules.ProjectLoadMoreRequest(
                state: CommitListPaginationRules.loadMoreRequestState(
                    isLoading: false,
                    hasMoreCommits: true,
                    currentPage: 6
                ),
                project: "repo"
            ),
            page: 6,
            pageSize: 40,
            existingItems: ["a"],
            currentPage: 6,
            hasMoreCommits: true,
            handlers: projectLoadMoreHandlers,
            applyAppend: { newItems, state in
                loadMoreOperationEvents.append("project-append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ","))")
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("project-failure:\(state.currentPage):\(state.hasMoreCommits)")
            },
            logFailure: { error in
                loadMoreOperationEvents.append("project-log:\(error.localizedDescription)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "project-load:repo:6:40",
            "project-append:a,repo-6-40:repo-6-40",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performLoadMoreOperation(
            page: 2,
            pageSize: 25,
            existingItems: ["a"],
            currentPage: 2,
            hasMoreCommits: false,
            loadItems: { _, _ -> [String] in
                loadMoreOperationEvents.append("load")
                throw NSError(domain: "CommitListPaginationRulesTest", code: 2)
            },
            id: { $0 },
            applyAppend: { newItems, state in
                loadMoreOperationEvents.append("append:\(newItems.count):\(state.decision.uniqueNewIDs.count)")
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("failure:\(state.currentPage):\(state.hasMoreCommits)")
            },
            logFailure: { _ in
                loadMoreOperationEvents.append("log")
            }
        )
        #expect(loadMoreOperationEvents == [
            "load",
            "failure:2:false",
            "log",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performRestoreLoadMoreOperation(
            targetID: "target",
            remainingAttempts: 1,
            page: 2,
            pageSize: 25,
            existingItems: ["a"],
            currentPage: 2,
            hasMoreCommits: true,
            loadItems: { page, limit in
                loadMoreOperationEvents.append("load:\(page):\(limit)")
                return ["b", "target"]
            },
            id: { $0 },
            applyAppend: { newItems, state, targetID, remainingAttempts in
                loadMoreOperationEvents.append(
                    "append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ",")):\(targetID):\(remainingAttempts)"
                )
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("failure:\(state.currentPage):\(state.hasMoreCommits)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "load:2:25",
            "append:b,target:b,target:target:1",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performRestoreLoadMoreOperation(
            targetID: "target",
            remainingAttempts: 2,
            page: 5,
            pageSize: 35,
            existingItems: ["a"],
            currentPage: 5,
            hasMoreCommits: true,
            handlers: CommitListPaginationRules.LoadMoreHandlers<String>(
                loadItems: { page, limit in
                    loadMoreOperationEvents.append("handler-load:\(page):\(limit)")
                    return ["target"]
                },
                id: { $0 }
            ),
            applyAppend: { newItems, state, targetID, remainingAttempts in
                loadMoreOperationEvents.append(
                    "handler-append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ",")):\(targetID):\(remainingAttempts)"
                )
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("handler-failure:\(state.currentPage):\(state.hasMoreCommits)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "handler-load:5:35",
            "handler-append:target:target:target:2",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performRestoreLoadMoreOperation(
            request: CommitListPaginationRules.ProjectLoadMoreRequest(
                state: CommitListPaginationRules.loadMoreRequestState(
                    isLoading: false,
                    hasMoreCommits: true,
                    currentPage: 7
                ),
                project: "repo"
            ),
            targetID: "target",
            remainingAttempts: 3,
            page: 7,
            pageSize: 45,
            existingItems: ["a"],
            currentPage: 7,
            hasMoreCommits: true,
            handlers: projectLoadMoreHandlers,
            applyAppend: { newItems, state, targetID, remainingAttempts in
                loadMoreOperationEvents.append(
                    "project-restore-append:\(newItems.joined(separator: ",")):\(state.decision.uniqueNewIDs.joined(separator: ",")):\(targetID):\(remainingAttempts)"
                )
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("project-restore-failure:\(state.currentPage):\(state.hasMoreCommits)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "project-load:repo:7:45",
            "project-restore-append:a,repo-7-45:repo-7-45:target:3",
        ])
        loadMoreOperationEvents = []
        await CommitListPaginationRules.performRestoreLoadMoreOperation(
            targetID: "target",
            remainingAttempts: 1,
            page: 2,
            pageSize: 25,
            existingItems: ["a"],
            currentPage: 2,
            hasMoreCommits: true,
            loadItems: { _, _ -> [String] in
                loadMoreOperationEvents.append("load")
                throw NSError(domain: "CommitListPaginationRulesTest", code: 3)
            },
            id: { $0 },
            applyAppend: { newItems, state, targetID, remainingAttempts in
                loadMoreOperationEvents.append("append:\(newItems.count):\(state.decision.uniqueNewIDs.count):\(targetID):\(remainingAttempts)")
            },
            applyFailure: { state in
                loadMoreOperationEvents.append("failure:\(state.currentPage):\(state.hasMoreCommits)")
            }
        )
        #expect(loadMoreOperationEvents == [
            "load",
            "failure:2:true",
        ])
        #expect(CommitListPaginationRules.uniqueNewIDs(
            existingIDs: ["a", "b"],
            newIDs: ["b", "c", "d"]
        ) == ["c", "d"])
        #expect(CommitListPaginationRules.uniqueItems(
            from: ["a", "b", "c", "d"],
            keepingIDs: ["b", "d"],
            id: { $0 }
        ) == ["b", "d"])
        #expect(CommitListPaginationRules.firstItem(
            matchingID: "c",
            in: ["a", "b", "c"],
            id: { $0 }
        ) == "c")
        #expect(CommitListPaginationRules.firstItem(
            matchingID: "z",
            in: ["a", "b", "c"],
            id: { $0 }
        ) == nil)
        #expect(CommitListPaginationRules.appendDecision(
            existingIDs: ["a", "b"],
            newIDs: ["b", "c", "d"],
            currentPage: 2
        ) == .init(uniqueNewIDs: ["c", "d"], nextPage: 3, hasMoreCommits: true))
        #expect(CommitListPaginationRules.appendDecision(
            existingIDs: ["a", "b"],
            newIDs: [],
            currentPage: 2
        ) == .init(uniqueNewIDs: [], nextPage: 2, hasMoreCommits: false))
        #expect(CommitListPaginationRules.appendResultState(
            existingIDs: ["a", "b"],
            newIDs: ["b", "c"],
            currentPage: 2
        ) == .init(
            decision: .init(uniqueNewIDs: ["c"], nextPage: 3, hasMoreCommits: true),
            appendsUniqueCommits: true,
            logsDuplicateWarning: false,
            rebuildsGraphAfterAppend: true,
            completionState: .init(isLoading: false, currentPage: 3, hasMoreCommits: true)
        ))
        #expect(CommitListPaginationRules.appendResultState(
            existingItems: [(hash: "a", index: 0), (hash: "b", index: 1)],
            newItems: [(hash: "b", index: 1), (hash: "c", index: 2)],
            currentPage: 2,
            id: \.hash
        ).decision.uniqueNewIDs == ["c"])
        var appendedItems: [String] = []
        var rebuildCount = 0
        var duplicateWarningCount = 0
        var appendPageStates: [CommitListPaginationRules.PageState] = []
        CommitListPaginationRules.performAppendResultState(
            CommitListPaginationRules.appendResultState(
                existingItems: ["a", "b"],
                newItems: ["b", "c"],
                currentPage: 2,
                id: { $0 }
            ),
            newItems: ["b", "c"],
            id: { $0 },
            appendItems: { appendedItems.append(contentsOf: $0) },
            rebuildGraph: { rebuildCount += 1 },
            logDuplicateWarning: { duplicateWarningCount += 1 },
            applyPageState: { appendPageStates.append($0) }
        )
        #expect(appendedItems == ["c"])
        #expect(rebuildCount == 1)
        #expect(duplicateWarningCount == 0)
        #expect(appendPageStates == [.init(isLoading: false, currentPage: 3, hasMoreCommits: true)])
        CommitListPaginationRules.performAppendResultState(
            CommitListPaginationRules.appendResultState(
                existingItems: ["a", "b"],
                newItems: ["a", "b"],
                currentPage: 2,
                id: { $0 }
            ),
            newItems: ["a", "b"],
            id: { $0 },
            appendItems: { appendedItems.append(contentsOf: $0) },
            rebuildGraph: { rebuildCount += 1 },
            logDuplicateWarning: { duplicateWarningCount += 1 },
            applyPageState: { appendPageStates.append($0) }
        )
        #expect(appendedItems == ["c"])
        #expect(rebuildCount == 1)
        #expect(duplicateWarningCount == 1)
        var restoreAppendedItems: [String] = []
        var restoreCurrentPages: [Int] = []
        var restoreRebuildCount = 0
        var restoreSelections: [String] = []
        var restoreLoadMore: [String] = []
        var restorePageStates: [CommitListPaginationRules.PageState] = []
        CommitListPaginationRules.performAppendResultForRestore(
            CommitListPaginationRules.appendResultState(
                existingItems: ["a", "b"],
                newItems: ["b", "c"],
                currentPage: 2,
                id: { $0 }
            ),
            newItems: ["b", "c"],
            targetID: "c",
            hasMoreCommitsForRestore: true,
            remainingAttempts: 2,
            id: { $0 },
            appendItems: { restoreAppendedItems.append(contentsOf: $0) },
            setCurrentPage: { restoreCurrentPages.append($0) },
            rebuildGraph: { restoreRebuildCount += 1 },
            select: { restoreSelections.append($0) },
            loadMore: { restoreLoadMore.append("\($0):\($1)") },
            applyPageState: { restorePageStates.append($0) }
        )
        #expect(restoreAppendedItems == ["c"])
        #expect(restoreCurrentPages == [3])
        #expect(restoreRebuildCount == 1)
        #expect(restoreSelections == ["c"])
        #expect(restoreLoadMore.isEmpty)
        #expect(restorePageStates == [.init(isLoading: false, currentPage: 3, hasMoreCommits: true)])
        CommitListPaginationRules.performAppendResultForRestore(
            CommitListPaginationRules.appendResultState(
                existingItems: ["a", "b"],
                newItems: ["b", "c"],
                currentPage: 2,
                id: { $0 }
            ),
            newItems: ["b", "c"],
            targetID: "z",
            hasMoreCommitsForRestore: true,
            remainingAttempts: 1,
            id: { $0 },
            appendItems: { restoreAppendedItems.append(contentsOf: $0) },
            setCurrentPage: { restoreCurrentPages.append($0) },
            rebuildGraph: { restoreRebuildCount += 1 },
            select: { restoreSelections.append($0) },
            loadMore: { restoreLoadMore.append("\($0):\($1)") },
            applyPageState: { restorePageStates.append($0) }
        )
        #expect(restoreLoadMore == ["z:1"])
        #expect(CommitListPaginationRules.appendResultState(
            existingIDs: ["a", "b"],
            newIDs: ["a", "b"],
            currentPage: 2
        ) == .init(
            decision: .init(uniqueNewIDs: [], nextPage: 3, hasMoreCommits: true),
            appendsUniqueCommits: false,
            logsDuplicateWarning: true,
            rebuildsGraphAfterAppend: false,
            completionState: .init(isLoading: false, currentPage: 3, hasMoreCommits: true)
        ))
        #expect(CommitListPaginationRules.appendCompletionState(
            from: .init(uniqueNewIDs: ["c"], nextPage: 3, hasMoreCommits: true),
            currentPage: 2
        ) == .init(isLoading: false, currentPage: 3, hasMoreCommits: true))
        #expect(CommitListPaginationRules.appendCompletionState(
            from: .init(uniqueNewIDs: [], nextPage: 2, hasMoreCommits: false),
            currentPage: 2
        ) == .init(isLoading: false, currentPage: 2, hasMoreCommits: false))
        #expect(CommitListPaginationRules.shouldAppendCommits(from: .init(
            uniqueNewIDs: ["c"],
            nextPage: 3,
            hasMoreCommits: true
        )))
        #expect(CommitListPaginationRules.shouldAppendCommits(from: .init(
            uniqueNewIDs: [],
            nextPage: 3,
            hasMoreCommits: true
        )) == false)
        #expect(CommitListPaginationRules.shouldRebuildGraphAfterAppend(
            decision: .init(uniqueNewIDs: ["c"], nextPage: 3, hasMoreCommits: true),
            didAppendUniqueCommits: true
        ))
        #expect(CommitListPaginationRules.shouldRebuildGraphAfterAppend(
            decision: .init(uniqueNewIDs: [], nextPage: 2, hasMoreCommits: false),
            didAppendUniqueCommits: false
        ))
        #expect(CommitListPaginationRules.stoppedState(
            currentPage: 4,
            hasMoreCommits: false
        ) == .init(isLoading: false, currentPage: 4, hasMoreCommits: false))
        #expect(CommitListPaginationRules.restoreSelectionAction(
            lastSelectedID: nil,
            loadedIDs: ["a", "b"],
            hasMoreCommits: true
        ) == .select("a"))
        #expect(CommitListPaginationRules.restoreSelectionAction(
            lastSelectedID: "b",
            loadedIDs: ["a", "b"],
            hasMoreCommits: true
        ) == .select("b"))
        #expect(CommitListPaginationRules.restoreSelectionAction(
            lastSelectedID: "b",
            loadedItems: [(hash: "a", index: 0), (hash: "b", index: 1)],
            hasMoreCommits: true,
            id: \.hash
        ) == .select("b"))
        #expect(CommitListPaginationRules.restoreSelectionAction(
            lastSelectedID: "z",
            loadedIDs: ["a", "b"],
            hasMoreCommits: true
        ) == .loadMore(targetID: "z"))
        #expect(CommitListPaginationRules.restoreSelectionAction(
            lastSelectedID: "z",
            loadedIDs: ["a", "b"],
            hasMoreCommits: false
        ) == .keepCurrent)
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreSelectionAction.select("b"),
            in: ["a", "b", "c"],
            id: { $0 }
        ) == "b")
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreSelectionAction.select(nil),
            in: ["a", "b", "c"],
            id: { $0 }
        ) == nil)
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreSelectionAction.loadMore(targetID: "b"),
            in: ["a", "b", "c"],
            id: { $0 }
        ) == nil)
        var restoreSelectionEvents: [String] = []
        CommitListPaginationRules.performRestoreSelectionAction(
            .select("b"),
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreSelectionEvents.append("select:\($0 ?? "nil")") },
            loadMore: { restoreSelectionEvents.append("load:\($0)") }
        )
        CommitListPaginationRules.performRestoreSelectionAction(
            .loadMore(targetID: "z"),
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreSelectionEvents.append("select:\($0 ?? "nil")") },
            loadMore: { restoreSelectionEvents.append("load:\($0)") }
        )
        CommitListPaginationRules.performRestoreSelectionAction(
            .keepCurrent,
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreSelectionEvents.append("select:\($0 ?? "nil")") },
            loadMore: { restoreSelectionEvents.append("load:\($0)") }
        )
        #expect(restoreSelectionEvents == ["select:b", "load:z"])
        var requiredRestoreSelectionEvents: [String] = []
        #expect(CommitListPaginationRules.performRequiredProjectRestoreSelection(
            project: Optional<String>.none,
            projectPath: { $0 },
            loadedItems: ["a", "b"],
            hasMoreCommits: true,
            id: { $0 },
            loadLastSelectedID: { _ in "z" },
            select: { requiredRestoreSelectionEvents.append("select:\($0 ?? "nil")") },
            loadMore: { requiredRestoreSelectionEvents.append("load:\($0)") }
        ) == false)
        #expect(CommitListPaginationRules.performRequiredProjectRestoreSelection(
            project: Optional("/repo"),
            projectPath: { $0 },
            loadedItems: ["a", "b"],
            hasMoreCommits: true,
            id: { $0 },
            loadLastSelectedID: { path in
                requiredRestoreSelectionEvents.append("path:\(path)")
                return "z"
            },
            select: { requiredRestoreSelectionEvents.append("select:\($0 ?? "nil")") },
            loadMore: { requiredRestoreSelectionEvents.append("load:\($0)") }
        ))
        #expect(requiredRestoreSelectionEvents == ["path:/repo", "load:z"])
        #expect(CommitListPaginationRules.restoreAfterAppendAction(
            targetID: "b",
            newIDs: ["a", "b"],
            hasMoreCommits: true,
            remainingAttempts: 2
        ) == .select("b"))
        #expect(CommitListPaginationRules.restoreAfterAppendAction(
            targetID: "b",
            newItems: [(hash: "a", index: 0), (hash: "b", index: 1)],
            hasMoreCommits: true,
            remainingAttempts: 2,
            id: \.hash
        ) == .select("b"))
        #expect(CommitListPaginationRules.restoreAfterAppendAction(
            targetID: "z",
            newIDs: ["a", "b"],
            hasMoreCommits: true,
            remainingAttempts: 2
        ) == .loadMore(targetID: "z", remainingAttempts: 2))
        #expect(CommitListPaginationRules.restoreAfterAppendAction(
            targetID: "z",
            newIDs: ["a", "b"],
            hasMoreCommits: true,
            remainingAttempts: 0
        ) == .none)
        #expect(CommitListPaginationRules.restoreAfterAppendAction(
            targetID: "z",
            newIDs: ["a", "b"],
            hasMoreCommits: false,
            remainingAttempts: 2
        ) == .none)
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreAfterAppendAction.select("b"),
            in: ["a", "b", "c"],
            id: { $0 }
        ) == "b")
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreAfterAppendAction.loadMore(
                targetID: "b",
                remainingAttempts: 1
            ),
            in: ["a", "b", "c"],
            id: { $0 }
        ) == nil)
        #expect(CommitListPaginationRules.selectedItem(
            for: CommitListPaginationRules.RestoreAfterAppendAction.none,
            in: ["a", "b", "c"],
            id: { $0 }
        ) == nil)
        var restoreAfterAppendEvents: [String] = []
        CommitListPaginationRules.performRestoreAfterAppendAction(
            .select("b"),
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreAfterAppendEvents.append("select:\($0)") },
            loadMore: { restoreAfterAppendEvents.append("load:\($0):\($1)") }
        )
        CommitListPaginationRules.performRestoreAfterAppendAction(
            .select("missing"),
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreAfterAppendEvents.append("select:\($0)") },
            loadMore: { restoreAfterAppendEvents.append("load:\($0):\($1)") }
        )
        CommitListPaginationRules.performRestoreAfterAppendAction(
            .loadMore(targetID: "z", remainingAttempts: 2),
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreAfterAppendEvents.append("select:\($0)") },
            loadMore: { restoreAfterAppendEvents.append("load:\($0):\($1)") }
        )
        CommitListPaginationRules.performRestoreAfterAppendAction(
            .none,
            in: ["a", "b", "c"],
            id: { $0 },
            select: { restoreAfterAppendEvents.append("select:\($0)") },
            loadMore: { restoreAfterAppendEvents.append("load:\($0):\($1)") }
        )
        #expect(restoreAfterAppendEvents == ["select:b", "load:z:2"])
        #expect(CommitListPaginationRules.refreshActionOnProjectChanged() == .refresh(
            reason: CommitListPaginationRules.projectChangedRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshActionOnBranchChanged() == .refresh(
            reason: CommitListPaginationRules.branchChangedRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshActionOnCommitSuccess() == .refresh(
            reason: CommitListPaginationRules.commitSuccessRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshActionOnAppear() == .refresh(
            reason: CommitListPaginationRules.appearRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshActionOnPullSuccess() == .refresh(
            reason: CommitListPaginationRules.pullSuccessRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshActionOnPushSuccess() == .none)
        #expect(CommitListPaginationRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: "/repo"))
        #expect(CommitListPaginationRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: nil) == false)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: true,
            didHeadChange: true
        ) == .refresh(reason: CommitListPaginationRules.gitDirectoryDidChangeRefreshReason))
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: true,
            didHeadChange: false
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: false,
            didHeadChange: true
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: true
        ) == .refresh(reason: CommitListPaginationRules.gitDirectoryDidChangeRefreshReason))
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: false
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: nil,
            didHeadChange: true
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .refresh(reason: CommitListPaginationRules.gitDirectoryDidChangeRefreshReason))
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/other"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: false
        ) == .none)
        #expect(CommitListPaginationRules.refreshActionOnApplicationWillBecomeActive() == .refresh(
            reason: CommitListPaginationRules.applicationWillBecomeActiveRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .projectChanged) == .refresh(
            reason: CommitListPaginationRules.projectChangedRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .branchChanged) == .refresh(
            reason: CommitListPaginationRules.branchChangedRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .commitSuccess) == .refresh(
            reason: CommitListPaginationRules.commitSuccessRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .appear) == .refresh(
            reason: CommitListPaginationRules.appearRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .pullSuccess) == .refresh(
            reason: CommitListPaginationRules.pullSuccessRefreshReason
        ))
        #expect(CommitListPaginationRules.refreshAction(for: .pushSuccess) == .none)
        #expect(CommitListPaginationRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: true
        )) == .refresh(reason: CommitListPaginationRules.gitDirectoryDidChangeRefreshReason))
        #expect(CommitListPaginationRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other",
            didHeadChange: true
        )) == .none)
        #expect(CommitListPaginationRules.refreshAction(
            gitDirectoryChangedEventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .refresh(reason: CommitListPaginationRules.gitDirectoryDidChangeRefreshReason))
        var refreshReasons: [String] = []
        CommitListPaginationRules.performRefreshAction(.refresh(reason: "reload")) { reason in
            refreshReasons.append(reason)
        }
        CommitListPaginationRules.performRefreshAction(.none) { reason in
            refreshReasons.append(reason)
        }
        CommitListPaginationRules.performRefreshEvent(.applicationWillBecomeActive) { reason in
            refreshReasons.append(reason)
        }
        CommitListPaginationRules.performGitDirectoryChangedRefreshEvent(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) { reason in
            refreshReasons.append(reason)
        }
        #expect(refreshReasons == [
            "reload",
            CommitListPaginationRules.applicationWillBecomeActiveRefreshReason,
            CommitListPaginationRules.gitDirectoryDidChangeRefreshReason,
        ])
    }

    @Test("commit graph presentation rules hide layout dependency")
    func commitGraphPresentationRules() {
        let rows = CommitGraphPresentationRules.rows(commits: [
            (id: "head", parentIDs: ["parent"]),
            (id: "parent", parentIDs: []),
        ])

        #expect(rows.map(\.commitID) == ["head", "parent"])
        #expect(CommitGraphPresentationRules.rowsByCommitID(from: rows)["head"]?.commitID == "head")
        #expect(CommitGraphPresentationRules.laneCount(from: rows) >= 1)
        #expect(CommitGraphPresentationRules.laneCount(from: []) == 1)
        let graphState = CommitGraphPresentationRules.graphState(commits: [
            (id: "head", parentIDs: ["parent"]),
            (id: "parent", parentIDs: []),
        ])
        #expect(graphState.rowsByCommitID["head"]?.commitID == "head")
        #expect(graphState.laneCount >= 1)
        let genericGraphState = CommitGraphPresentationRules.graphState(
            from: [
                (hash: "head", parentHashes: ["parent"]),
                (hash: "parent", parentHashes: []),
            ],
            id: \.hash,
            parentIDs: \.parentHashes
        )
        #expect(genericGraphState.rowsByCommitID["head"]?.commitID == "head")
        var appliedRowsByCommitID: [String: CommitGraphPresentationRules.Row] = [:]
        var appliedLaneCount = 0
        CommitGraphPresentationRules.performGraphState(
            genericGraphState,
            setRowsByCommitID: { appliedRowsByCommitID = $0 },
            setLaneCount: { appliedLaneCount = $0 }
        )
        #expect(appliedRowsByCommitID["head"]?.commitID == "head")
        #expect(appliedLaneCount == genericGraphState.laneCount)
        #expect(CommitGraphPresentationRules.row(
            for: "head",
            showsCommitGraph: true,
            rowsByCommitID: graphState.rowsByCommitID
        )?.commitID == "head")
        #expect(CommitGraphPresentationRules.row(
            for: "head",
            showsCommitGraph: false,
            rowsByCommitID: graphState.rowsByCommitID
        ) == nil)
    }

    @Test("commit message rules format default subject and coauthors")
    func commitMessageRules() async throws {
        let coAuthors = [
            CoAuthor(name: "Grace Hopper", email: "grace@example.com"),
            CoAuthor(name: "Ada Lovelace", email: "ada@example.com"),
        ]

        #expect(CommitMessageRules.defaultMessage(for: .Feature, style: .plain) == "Implement a new feature")
        #expect(CommitMessageRules.defaultMessage(for: .Feature, style: .lowercase) == "implement a new feature")
        #expect(CommitMessageRules.initialSubject(category: .Feature, style: .plain) == "Implement a new feature")
        #expect(CommitMessageRules.formAppearanceState(
            category: .Feature,
            currentStyle: .emoji,
            projectStyle: .lowercase
        ) == .init(subject: "implement a new feature", style: .lowercase))
        #expect(CommitMessageRules.formAppearanceState(
            category: .Feature,
            currentStyle: .plain,
            projectStyle: nil
        ) == .init(subject: "Implement a new feature", style: .plain))
        struct CommitStyleProjectStub {
            let style: CommitStyle
        }
        #expect(CommitMessageRules.formAppearanceState(
            category: .Feature,
            currentStyle: .emoji,
            project: Optional(CommitStyleProjectStub(style: .plain)),
            projectStyle: \.style
        ) == .init(subject: "Implement a new feature", style: .plain))
        #expect(CommitMessageRules.formAppearanceState(
            category: .Feature,
            currentStyle: .lowercase,
            project: Optional<CommitStyleProjectStub>.none,
            projectStyle: \.style
        ) == .init(subject: "implement a new feature", style: .lowercase))
        var appliedFormSubject = ""
        var appliedFormStyle: CommitStyle = .emoji
        CommitMessageRules.performFormAppearanceState(
            .init(subject: "Subject", style: .lowercase),
            setSubject: { appliedFormSubject = $0 },
            setStyle: { appliedFormStyle = $0 }
        )
        #expect(appliedFormSubject == "Subject")
        #expect(appliedFormStyle == .lowercase)
        var formAppearEvents: [String] = []
        CommitMessageRules.performFormAppear(
            appearanceState: .init(subject: "Appear", style: .plain),
            setSubject: { appliedFormSubject = $0 },
            setStyle: { appliedFormStyle = $0 },
            loadAutocomplete: { formAppearEvents.append("autocomplete") }
        )
        #expect(appliedFormSubject == "Appear")
        #expect(appliedFormStyle == .plain)
        #expect(formAppearEvents == ["autocomplete"])
        CommitMessageRules.performAutocompleteRefreshTrigger {
            formAppearEvents.append("refresh")
        }
        #expect(formAppearEvents == ["autocomplete", "refresh"])
        var savedStyleEvents: [(String, CommitStyle)] = []
        #expect(CommitMessageRules.performProjectStyleSave(
            Optional<String>.none,
            style: .plain
        ) { project, style in
            savedStyleEvents.append((project, style))
        } == false)
        #expect(CommitMessageRules.performProjectStyleSave(
            Optional("repo"),
            style: .lowercase
        ) { project, style in
            savedStyleEvents.append((project, style))
        })
        #expect(savedStyleEvents.map(\.0) == ["repo"])
        #expect(savedStyleEvents.map(\.1) == [.lowercase])
        #expect(CommitMessageRules.performProjectStyleSaveCommand(
            project: Optional("repo"),
            style: .emoji
        ) { request in
            savedStyleEvents.append((request.project, request.style))
        })
        #expect(CommitMessageRules.performProjectStyleSaveCommand(
            project: Optional<String>.none,
            style: .plain
        ) { request in
            savedStyleEvents.append((request.project, request.style))
        } == false)
        #expect(savedStyleEvents.map(\.0) == ["repo", "repo"])
        #expect(savedStyleEvents.map(\.1) == [.lowercase, .emoji])
        #expect(CommitMessageRules.subjectAfterCategoryChange(category: .Bugfix, style: .lowercase) == "fix a bug")
        CommitMessageRules.performProjectDidCommit(
            category: .Feature,
            style: .lowercase,
            setSubject: { appliedFormSubject = $0 }
        )
        #expect(appliedFormSubject == "implement a new feature")
        CommitMessageRules.performCategoryDidChange(
            category: .Bugfix,
            style: .plain,
            setSubject: { appliedFormSubject = $0 }
        )
        #expect(appliedFormSubject == "Fix a bug")

        let message = CommitMessageRules.formattedMessage(
            subject: "",
            category: .Bugfix,
            style: .plain,
            coAuthors: coAuthors
        )

        #expect(message.hasPrefix("Bugfix:  Auto Committed by GitOK"))
        #expect(message.contains("Co-authored-by: Grace Hopper <grace@example.com>"))
        #expect(message.contains("Co-authored-by: Ada Lovelace <ada@example.com>"))
        #expect(CommitMessageRules.submitMessage("") == CommitMessageRules.fallbackCommitMessage)
        #expect(CommitMessageRules.submitMessage("custom") == "custom")
        #expect(CommitMessageRules.submitPlan(
            message: "",
            hasStagedChanges: false,
            commitOnly: true
        ) == .init(
            message: CommitMessageRules.fallbackCommitMessage,
            addsAllFiles: true,
            pushesAfterCommit: false
        ))
        #expect(CommitMessageRules.submitPlan(
            message: "custom",
            hasStagedChanges: true,
            commitOnly: false
        ) == .init(
            message: "custom",
            addsAllFiles: false,
            pushesAfterCommit: true
        ))
        #expect(CommitMessageRules.submitSteps(for: .init(
            message: "custom",
            addsAllFiles: true,
            pushesAfterCommit: false
        )) == [.addAllFiles, .commit])
        #expect(CommitMessageRules.submitSteps(for: .init(
            message: "custom",
            addsAllFiles: false,
            pushesAfterCommit: true
        )) == [.commit, .push])
        #expect(CommitMessageRules.submitExecutionState(
            message: "",
            hasStagedChanges: false,
            commitOnly: false
        ) == .init(
            plan: .init(
                message: CommitMessageRules.fallbackCommitMessage,
                addsAllFiles: true,
                pushesAfterCommit: true
            ),
            steps: [.addAllFiles, .commit, .push]
        ))
        let asyncSubmitExecutionState = try await CommitMessageRules.submitExecutionState(
            message: "custom",
            commitOnly: false,
            hasStagedChanges: { true }
        )
        #expect(asyncSubmitExecutionState == .init(
            plan: .init(message: "custom", addsAllFiles: false, pushesAfterCommit: true),
            steps: [.commit, .push]
        ))
        var requiredMessageProjectEvents: [String] = []
        #expect(CommitMessageRules.performRequiredProject(Optional<String>.none) {
            requiredMessageProjectEvents.append($0)
        } == false)
        #expect(CommitMessageRules.performRequiredProject(Optional("repo")) {
            requiredMessageProjectEvents.append($0)
        })
        #expect(requiredMessageProjectEvents == ["repo"])
        var requiredSubmitEvents: [String] = []
        #expect(CommitMessageRules.performRequiredProjectSubmit(
            project: Optional<String>.none,
            message: "message",
            commitOnly: true,
            perform: { request, project in
                requiredSubmitEvents.append("\(project):\(request.message):\(request.commitOnly)")
            }
        ) == false)
        #expect(CommitMessageRules.performRequiredProjectSubmit(
            project: Optional("repo"),
            message: "message",
            commitOnly: false,
            perform: { request, project in
                requiredSubmitEvents.append("\(project):\(request.message):\(request.commitOnly)")
            }
        ))
        #expect(requiredSubmitEvents == ["repo:message:false"])
        var requiredSubmitCommandEvents: [String] = []
        #expect(CommitMessageRules.performRequiredProjectSubmitCommand(
            project: Optional<String>.none,
            message: "message",
            commitOnly: true,
            perform: { command in
                requiredSubmitCommandEvents.append("\(command.project):\(command.request.message):\(command.request.commitOnly)")
            }
        ) == false)
        #expect(CommitMessageRules.performRequiredProjectSubmitCommand(
            project: Optional("repo"),
            message: "message",
            commitOnly: false,
            perform: { command in
                requiredSubmitCommandEvents.append("\(command.project):\(command.request.message):\(command.request.commitOnly)")
            }
        ))
        #expect(requiredSubmitCommandEvents == ["repo:message:false"])
        let mentions = CommitMessageRules.autocompleteUserMentions(namesAndEmails: [
            (name: "Grace Hopper", email: "grace@example.com")
        ])
        #expect(mentions.contains("@grace"))
        #expect(mentions.contains("@grace-hopper"))
        #expect(CommitMessageRules.autocompleteNameEmailPairs(coAuthors: [
            CoAuthor(name: "Ada Lovelace", email: "ada@example.com")
        ]).first?.name == "Ada Lovelace")
        #expect(CommitMessageRules.autocompleteNameEmailPairs(coAuthors: [
            CoAuthor(name: "Ada Lovelace", email: "ada@example.com")
        ]).first?.email == "ada@example.com")
        #expect(CommitMessageRules.autocompleteBranchNames(
            localBranches: ["feature/#12-local"],
            remoteBranches: ["origin/bugfix/#34-remote"]
        ) == ["feature/#12-local", "origin/bugfix/#34-remote"])
        #expect(CommitMessageRules.autocompleteIssueReferences(
            branchNames: ["feature/#12-local", "origin/bugfix/#34-remote"]
        ) == ["#12", "#34"])
        let autocompleteState = CommitMessageRules.autocompleteState(
            namesAndEmails: [(name: "Grace Hopper", email: "grace@example.com")],
            localBranches: ["feature/#12-local"],
            remoteBranches: ["origin/bugfix/#34-remote"]
        )
        #expect(autocompleteState.userMentions.contains("@grace"))
        #expect(autocompleteState.issueReferences == ["#12", "#34"])
        #expect(CommitMessageRules.autocompleteState(
            namesAndEmails: [],
            localBranches: [(name: "feature/#12-local", isHead: false)],
            localBranchName: \.name,
            remoteBranches: ["origin/bugfix/#34-remote"]
        ).issueReferences == ["#12", "#34"])
        #expect(CommitMessageRules.autocompleteState(
            namesAndEmails: [],
            localBranches: [],
            remoteBranches: []
        ) == .init(userMentions: [], issueReferences: []))
        #expect(CommitMessageRules.autocompleteInitialState(
            namesAndEmails: [(name: "Grace Hopper", email: "grace@example.com")]
        ).userMentions.contains("@grace"))
        #expect(CommitMessageRules.autocompleteInitialState(
            namesAndEmails: [(name: "Grace Hopper", email: "grace@example.com")]
        ).issueReferences.isEmpty)
        var autocompleteUserMentions: [[String]] = []
        var autocompleteIssueReferences: [[String]] = []
        CommitMessageRules.performAutocompleteInitialState(
            autocompleteState,
            hasProject: true,
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteUserMentions.count == 1)
        #expect(autocompleteIssueReferences.isEmpty)
        CommitMessageRules.performAutocompleteInitialState(
            autocompleteState,
            hasProject: false,
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteIssueReferences == [["#12", "#34"]])
        CommitMessageRules.performAutocompleteState(
            autocompleteState,
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteIssueReferences == [["#12", "#34"], ["#12", "#34"]])
        await CommitMessageRules.performProjectAutocompleteLoad(
            namesAndEmails: [(name: "Linus Torvalds", email: "linus@example.com")],
            loadLocalBranchNames: { ["feature/#56-local"] },
            loadRemoteBranches: { throw NSError(domain: "GitOKTests", code: 1) },
            setAutocomplete: { state in
                autocompleteUserMentions.append(state.userMentions)
                autocompleteIssueReferences.append(state.issueReferences)
            }
        )
        #expect(autocompleteUserMentions.last?.contains("@linus") == true)
        #expect(autocompleteIssueReferences.last == ["#56"])
        autocompleteUserMentions.removeAll()
        autocompleteIssueReferences.removeAll()
        await CommitMessageRules.performAutocompleteLoadOperation(
            namesAndEmails: [(name: "Ada Lovelace", email: "ada@example.com")],
            hasProject: false,
            loadLocalBranchNames: nil,
            loadRemoteBranches: nil,
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteUserMentions.count == 1)
        #expect(autocompleteUserMentions.first?.contains("@ada") == true)
        #expect(autocompleteIssueReferences == [[]])
        await CommitMessageRules.performAutocompleteLoadOperation(
            namesAndEmails: [(name: "Ada Lovelace", email: "ada@example.com")],
            hasProject: true,
            loadLocalBranchNames: { ["feature/#78-project"] },
            loadRemoteBranches: { ["origin/bugfix/#90-project"] },
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteUserMentions.last?.contains("@ada") == true)
        #expect(autocompleteIssueReferences.last == ["#78", "#90"])
        autocompleteUserMentions.removeAll()
        autocompleteIssueReferences.removeAll()
        var autocompleteProjectLoads: [String] = []
        struct BranchNameStub {
            let name: String
        }
        await CommitMessageRules.performProjectAutocompleteLoadOperation(
            namesAndEmails: [(name: "Katherine Johnson", email: "katherine@example.com")],
            project: Optional("repo"),
            loadLocalBranches: { project in
                autocompleteProjectLoads.append("local:\(project)")
                return [BranchNameStub(name: "feature/#101-local")]
            },
            localBranchName: \.name,
            loadRemoteBranches: { project in
                autocompleteProjectLoads.append("remote:\(project)")
                return ["origin/bugfix/#202-remote"]
            },
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteProjectLoads == ["local:repo", "remote:repo"])
        #expect(autocompleteUserMentions.last?.contains("@katherine") == true)
        #expect(autocompleteIssueReferences.last == ["#101", "#202"])
        var autocompleteStates: [CommitMessageRules.AutocompleteState] = []
        await CommitMessageRules.performProjectAutocompleteLoadOperation(
            namesAndEmails: [(name: "Margaret Hamilton", email: "margaret@example.com")],
            project: Optional("repo"),
            loadLocalBranches: { _ in [BranchNameStub(name: "feature/#303-local")] },
            localBranchName: \.name,
            loadRemoteBranches: { _ in [] },
            setAutocomplete: { autocompleteStates.append($0) }
        )
        #expect(autocompleteStates.first?.userMentions.contains("@margaret") == true)
        #expect(autocompleteStates.first?.issueReferences.isEmpty == true)
        #expect(autocompleteStates.last?.userMentions.contains("@margaret") == true)
        #expect(autocompleteStates.last?.issueReferences == ["#303"])
        autocompleteStates.removeAll()
        autocompleteProjectLoads.removeAll()
        await CommitMessageRules.performProjectAutocompleteLoadCommand(
            namesAndEmails: [(name: "Margaret Hamilton", email: "margaret@example.com")],
            project: Optional("repo"),
            loadLocalBranches: { request in
                autocompleteProjectLoads.append("local:\(request.project)")
                return [BranchNameStub(name: "feature/#505-local")]
            },
            localBranchName: \.name,
            loadRemoteBranches: { request in
                autocompleteProjectLoads.append("remote:\(request.project)")
                return ["origin/bugfix/#606-remote"]
            },
            setAutocomplete: { autocompleteStates.append($0) }
        )
        #expect(autocompleteProjectLoads == ["local:repo", "remote:repo"])
        #expect(autocompleteStates.first?.userMentions.contains("@margaret") == true)
        #expect(autocompleteStates.first?.issueReferences.isEmpty == true)
        #expect(autocompleteStates.last?.issueReferences == ["#505", "#606"])
        autocompleteStates.removeAll()
        autocompleteProjectLoads.removeAll()
        let autocompleteHandlers = CommitMessageRules.ProjectAutocompleteLoadHandlers<String, BranchNameStub>(
            loadLocalBranches: { project in
                autocompleteProjectLoads.append("handler-local:\(project)")
                return [BranchNameStub(name: "feature/#909-local")]
            },
            localBranchName: \.name,
            loadRemoteBranches: { project in
                autocompleteProjectLoads.append("handler-remote:\(project)")
                return ["origin/bugfix/#1001-remote"]
            }
        )
        await CommitMessageRules.performProjectAutocompleteLoadCommand(
            namesAndEmails: [(name: "Margaret Hamilton", email: "margaret@example.com")],
            project: Optional("repo"),
            handlers: autocompleteHandlers,
            setAutocomplete: { autocompleteStates.append($0) }
        )
        #expect(autocompleteProjectLoads == ["handler-local:repo", "handler-remote:repo"])
        #expect(autocompleteStates.first?.userMentions.contains("@margaret") == true)
        #expect(autocompleteStates.first?.issueReferences.isEmpty == true)
        #expect(autocompleteStates.last?.issueReferences == ["#909", "#1001"])
        autocompleteStates.removeAll()
        autocompleteProjectLoads.removeAll()
        await CommitMessageRules.performProjectAutocompleteLoadCommand(
            namesAndEmails: [(name: "Margaret Hamilton", email: "margaret@example.com")],
            project: Optional<String>.none,
            loadLocalBranches: { request in
                autocompleteProjectLoads.append("local:\(request.project)")
                return [BranchNameStub(name: "feature/#707-local")]
            },
            localBranchName: \.name,
            loadRemoteBranches: { request in
                autocompleteProjectLoads.append("remote:\(request.project)")
                return ["origin/bugfix/#808-remote"]
            },
            setAutocomplete: { autocompleteStates.append($0) }
        )
        #expect(autocompleteProjectLoads.isEmpty)
        #expect(autocompleteStates.count == 1)
        #expect(autocompleteStates.first?.issueReferences.isEmpty == true)
        autocompleteProjectLoads.removeAll()
        autocompleteUserMentions.removeAll()
        autocompleteIssueReferences.removeAll()
        await CommitMessageRules.performProjectAutocompleteLoadOperation(
            namesAndEmails: [(name: "Katherine Johnson", email: "katherine@example.com")],
            project: Optional<String>.none,
            loadLocalBranches: { project in
                autocompleteProjectLoads.append("local:\(project)")
                return [BranchNameStub(name: "feature/#303-local")]
            },
            localBranchName: \.name,
            loadRemoteBranches: { project in
                autocompleteProjectLoads.append("remote:\(project)")
                return ["origin/bugfix/#404-remote"]
            },
            setUserMentions: { autocompleteUserMentions.append($0) },
            setIssueReferences: { autocompleteIssueReferences.append($0) }
        )
        #expect(autocompleteProjectLoads.isEmpty)
        #expect(autocompleteUserMentions.last?.contains("@katherine") == true)
        #expect(autocompleteIssueReferences == [[]])
        #expect(CommitMessageRules.shouldLoadProjectAutocomplete(hasProject: true))
        #expect(CommitMessageRules.shouldLoadProjectAutocomplete(hasProject: false) == false)
        #expect(CommitMessageRules.shouldReplaceSubjectOnStyleChange(currentSubject: "", category: .Feature))
        #expect(CommitMessageRules.shouldReplaceSubjectOnStyleChange(
            currentSubject: "Implement a new feature",
            category: .Feature
        ))
        #expect(CommitMessageRules.shouldReplaceSubjectOnStyleChange(
            currentSubject: "custom subject",
            category: .Feature
        ) == false)
        #expect(CommitMessageRules.subjectAfterStyleChange(
            currentSubject: "Implement a new feature",
            category: .Feature,
            newStyle: .lowercase
        ) == "implement a new feature")
        #expect(CommitMessageRules.subjectAfterStyleChange(
            currentSubject: "custom subject",
            category: .Feature,
            newStyle: .lowercase
        ) == nil)
        var performedStyleSubject = ""
        #expect(CommitMessageRules.performSubjectAfterStyleChange(
            currentSubject: "Implement a new feature",
            category: .Feature,
            newStyle: .lowercase,
            setSubject: { performedStyleSubject = $0 }
        ))
        #expect(performedStyleSubject == "implement a new feature")
        #expect(CommitMessageRules.performSubjectAfterStyleChange(
            currentSubject: "custom subject",
            category: .Feature,
            newStyle: .lowercase,
            setSubject: { performedStyleSubject = $0 }
        ) == false)
        #expect(performedStyleSubject == "implement a new feature")
        #expect(CommitMessageRules.activityStatus(.addingFiles).isEmpty == false)
        #expect(CommitMessageRules.activityStatus(.committing).isEmpty == false)
        #expect(CommitMessageRules.activityStatus(.pushing).isEmpty == false)
        #expect(CommitMessageRules.activityStatus(for: .addAllFiles) == CommitMessageRules.activityStatus(.addingFiles))
        #expect(CommitMessageRules.activityStatus(for: .commit) == CommitMessageRules.activityStatus(.committing))
        #expect(CommitMessageRules.activityStatus(for: .push) == CommitMessageRules.activityStatus(.pushing))
        #expect(CommitMessageRules.submitFailureLogMessage(errorDescription: "boom").contains("boom"))
        var submitOperations: [String] = []
        try await CommitMessageRules.performSubmitStep(
            .addAllFiles,
            onAddAllFiles: { submitOperations.append("add") },
            onCommit: { submitOperations.append("commit") },
            onPush: { submitOperations.append("push") }
        )
        try await CommitMessageRules.performSubmitStep(
            .commit,
            onAddAllFiles: { submitOperations.append("add") },
            onCommit: { submitOperations.append("commit") },
            onPush: { submitOperations.append("push") }
        )
        try await CommitMessageRules.performSubmitStep(
            .push,
            onAddAllFiles: { submitOperations.append("add") },
            onCommit: { submitOperations.append("commit") },
            onPush: { submitOperations.append("push") }
        )
        #expect(submitOperations == ["add", "commit", "push"])
        var executionStatuses: [String] = []
        var executionOperations: [String] = []
        try await CommitMessageRules.performSubmitExecutionState(
            .init(
                plan: .init(message: "message", addsAllFiles: true, pushesAfterCommit: true),
                steps: [.addAllFiles, .commit, .push]
            ),
            setStatus: { executionStatuses.append($0) },
            onAddAllFiles: { executionOperations.append("add") },
            onCommit: { executionOperations.append("commit") },
            onPush: { executionOperations.append("push") }
        )
        #expect(executionStatuses == [
            CommitMessageRules.activityStatus(for: .addAllFiles),
            CommitMessageRules.activityStatus(for: .commit),
            CommitMessageRules.activityStatus(for: .push),
        ])
        #expect(executionOperations == ["add", "commit", "push"])
        var submitOperationEvents: [String] = []
        await CommitMessageRules.performSubmitOperation(
            message: "message",
            commitOnly: false,
            hasStagedChanges: { false },
            setStatus: { submitOperationEvents.append("status:\($0)") },
            onAddAllFiles: { submitOperationEvents.append("add") },
            onCommit: { submitOperationEvents.append("commit:\($0.message)") },
            onPush: { submitOperationEvents.append("push") },
            showSuccessMessage: { submitOperationEvents.append("success:\($0.isEmpty == false)") },
            handleFailure: { submitOperationEvents.append("failure:\($0.localizedDescription)") },
            clearStatus: { submitOperationEvents.append("clear") }
        )
        #expect(submitOperationEvents == [
            "status:\(CommitMessageRules.activityStatus(for: .addAllFiles))",
            "add",
            "status:\(CommitMessageRules.activityStatus(for: .commit))",
            "commit:message",
            "status:\(CommitMessageRules.activityStatus(for: .push))",
            "push",
            "success:true",
            "clear",
        ])
        enum SubmitOperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "submit failed"
            }
        }
        submitOperationEvents = []
        await CommitMessageRules.performSubmitOperation(
            message: "message",
            commitOnly: true,
            hasStagedChanges: { true },
            setStatus: { submitOperationEvents.append("status:\($0)") },
            onAddAllFiles: { submitOperationEvents.append("add") },
            onCommit: { _ in throw SubmitOperationError.failed },
            onPush: { submitOperationEvents.append("push") },
            showSuccessMessage: { submitOperationEvents.append("success:\($0)") },
            handleFailure: { submitOperationEvents.append("failure:\($0.localizedDescription)") },
            clearStatus: { submitOperationEvents.append("clear") }
        )
        #expect(submitOperationEvents == [
            "status:\(CommitMessageRules.activityStatus(for: .commit))",
            "failure:submit failed",
            "clear",
        ])
        submitOperationEvents = []
        let submitHandlers = CommitMessageRules.SubmitOperationHandlers(
            hasStagedChanges: { false },
            addAllFiles: { submitOperationEvents.append("handler-add") },
            commit: { submitOperationEvents.append("handler-commit:\($0.message)") },
            push: { submitOperationEvents.append("handler-push") }
        )
        await CommitMessageRules.performSubmitOperation(
            request: .init(message: "handler message", commitOnly: false),
            handlers: submitHandlers,
            setStatus: { submitOperationEvents.append("status:\($0)") },
            showSuccessMessage: { submitOperationEvents.append("success:\($0.isEmpty == false)") },
            handleFailure: { submitOperationEvents.append("failure:\($0.localizedDescription)") },
            clearStatus: { submitOperationEvents.append("clear") }
        )
        #expect(submitOperationEvents == [
            "status:\(CommitMessageRules.activityStatus(for: .addAllFiles))",
            "handler-add",
            "status:\(CommitMessageRules.activityStatus(for: .commit))",
            "handler-commit:handler message",
            "status:\(CommitMessageRules.activityStatus(for: .push))",
            "handler-push",
            "success:true",
            "clear",
        ])
        submitOperationEvents = []
        let projectSubmitHandlers = CommitMessageRules.ProjectSubmitOperationHandlers<String>(
            hasStagedChanges: { project in
                submitOperationEvents.append("project-has-staged:\(project)")
                return false
            },
            addAllFiles: { project in
                submitOperationEvents.append("project-add:\(project)")
            },
            commit: { project, plan in
                submitOperationEvents.append("project-commit:\(project):\(plan.message)")
            },
            push: { project in
                submitOperationEvents.append("project-push:\(project)")
            }
        )
        await CommitMessageRules.performSubmitOperation(
            command: .init(
                request: .init(message: "project handler message", commitOnly: false),
                project: "repo"
            ),
            handlers: projectSubmitHandlers,
            setStatus: { submitOperationEvents.append("status:\($0)") },
            showSuccessMessage: { submitOperationEvents.append("success:\($0.isEmpty == false)") },
            handleFailure: { submitOperationEvents.append("failure:\($0.localizedDescription)") },
            clearStatus: { submitOperationEvents.append("clear") }
        )
        #expect(submitOperationEvents == [
            "project-has-staged:repo",
            "status:\(CommitMessageRules.activityStatus(for: .addAllFiles))",
            "project-add:repo",
            "status:\(CommitMessageRules.activityStatus(for: .commit))",
            "project-commit:repo:project handler message",
            "status:\(CommitMessageRules.activityStatus(for: .push))",
            "project-push:repo",
            "success:true",
            "clear",
        ])
        #expect(CommitMessageRules.successMessage(commitOnly: true).isEmpty == false)
        #expect(CommitMessageRules.successMessage(commitOnly: false).isEmpty == false)
        #expect(CommitMessageRules.submitSuccessState(commitOnly: true) == .init(
            message: CommitMessageRules.successMessage(commitOnly: true),
            clearsActivityStatus: true
        ))
    }

    @Test("remote sync rules classify credential errors and retry status")
    func remoteSyncRules() async throws {
        #expect(CommitRemoteSyncRules.pushRetryDelays == [2_000_000_000, 4_000_000_000])
        #expect(CommitRemoteSyncRules.remoteStatusRefreshInterval == 60)
        #expect(CommitRemoteSyncRules.credentialRetryDelayNanoseconds == 500_000_000)
        #expect(CommitRemoteSyncRules.statusClearDelayNanoseconds == 2_000_000_000)
        #expect(CommitRemoteSyncRules.appActivationRefreshDelayNanoseconds == 500_000_000)
        #expect(CommitRemoteSyncRules.fallbackErrorDomain == "GitOK")
        #expect(CommitRemoteSyncRules.fallbackErrorCode == -1)
        #expect(CommitRemoteSyncRules.fallbackError().domain == CommitRemoteSyncRules.fallbackErrorDomain)
        #expect(CommitRemoteSyncRules.fallbackError().code == CommitRemoteSyncRules.fallbackErrorCode)
        #expect(CommitRemoteSyncRules.fallbackErrorDescription().isEmpty == false)
        #expect(CommitRemoteSyncRules.gitHeadChangedEventInfoKey == "headChanged")
        #expect(CommitRemoteSyncRules.defaultCredentialHost == "github.com")
        #expect(CommitRemoteSyncRules.missingProjectLogMessage() == "No project found")
        #expect(CommitRemoteSyncRules.changedFileCountFailureLogMessage(errorDescription: "boom") == "❌ Failed to load changed file count: boom")
        #expect(CommitRemoteSyncRules.syncStatusLoadLogMessage(projectPath: "/repo") == "</repo>Loading sync status")
        #expect(CommitRemoteSyncRules.unpushedCountFailureLogMessage(errorDescription: "boom") == "❌ Failed to load unpushed commits count: boom")
        #expect(CommitRemoteSyncRules.unpulledCountFailureLogMessage(errorDescription: "boom") == "❌ Failed to load unpulled commits count: boom")
        #expect(CommitRemoteSyncRules.syncStatusUpdatedLogMessage(unpushedCount: 2, unpulledCount: 3) == "✅ Sync status updated: unpushed=2, unpulled=3")
        #expect(CommitRemoteSyncRules.pullOperationLogMessage(projectPath: "/repo") == "</repo>Performing git pull")
        #expect(CommitRemoteSyncRules.pullSuccessLogMessage() == "✅ Git pull succeeded")
        #expect(CommitRemoteSyncRules.pullFailureLogMessage(errorDescription: "boom") == "❌ Git pull failed: boom")
        #expect(CommitRemoteSyncRules.pushOperationLogMessage(projectPath: "/repo") == "</repo>Performing git push")
        #expect(CommitRemoteSyncRules.systemGitPushFailureLogMessage(errorDescription: "boom") == "CLI push also failed: boom")
        #expect(CommitRemoteSyncRules.pushSuccessLogMessage(retryAttempt: nil) == "✅ Git push succeeded")
        #expect(CommitRemoteSyncRules.pushSuccessLogMessage(retryAttempt: 2) == "✅ Git push succeeded after retry 2")
        #expect(CommitRemoteSyncRules.pushRetryStartLogMessage() == "Network error, starting retry with backoff")
        #expect(CommitRemoteSyncRules.pushRetryFailureLogMessage(retryAttempt: 1) == "Retry 1 failed")
        #expect(CommitRemoteSyncRules.remoteStatusTimerFiredLogMessage() == "⏰ Timer fired, checking remote status")
        #expect(CommitRemoteSyncRules.remoteStatusTimerStartedLogMessage(interval: 60) == "⏰ Started remote status timer (interval: 60.0s)")
        #expect(CommitRemoteSyncRules.remoteStatusTimerStoppedLogMessage() == "⏰ Stopped remote status timer")
        #expect(CommitRemoteSyncRules.refreshActionOnAppear() == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnTap() == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshActionOnProjectChanged() == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnProjectDidCommit() == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnProjectDidPush() == .syncStatusOnly)
        #expect(CommitRemoteSyncRules.refreshActionOnProjectDidPull() == .syncStatusOnly)
        #expect(CommitRemoteSyncRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: "/repo"))
        #expect(CommitRemoteSyncRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: nil) == false)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: false,
            didHeadChange: true
        ) == .none)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: true,
            didHeadChange: false
        ) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            isCurrentProject: true,
            didHeadChange: true
        ) == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: false
        ) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: true
        ) == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other",
            didHeadChange: true
        ) == .none)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: false
        ) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .full)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/other"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .none)
        #expect(CommitRemoteSyncRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .none)
        #expect(CommitRemoteSyncRules.refreshActionOnAppDidBecomeActive() == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .appear) == .full)
        #expect(CommitRemoteSyncRules.refreshAction(for: .tap) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .projectChanged) == .full)
        #expect(CommitRemoteSyncRules.refreshAction(for: .projectDidCommit) == .full)
        #expect(CommitRemoteSyncRules.refreshAction(for: .projectDidPush) == .syncStatusOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .projectDidPull) == .syncStatusOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .appDidBecomeActive) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: true
        )) == .full)
        #expect(CommitRemoteSyncRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo",
            didHeadChange: false
        )) == .changedFilesOnly)
        #expect(CommitRemoteSyncRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other",
            didHeadChange: true
        )) == .none)
        #expect(CommitRemoteSyncRules.refreshAction(
            gitDirectoryChangedEventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: true
        ) == .full)
        #expect(CommitRemoteSyncRules.retryActionAfterCredentialSave(operation: nil) == nil)
        #expect(CommitRemoteSyncRules.retryActionAfterCredentialSave(operation: .push) == .init(
            operation: .push,
            delayNanoseconds: CommitRemoteSyncRules.credentialRetryDelayNanoseconds
        ))
        #expect(CommitRemoteSyncRules.retryActionAfterSSHHelp(operation: .pull) == .init(
            operation: .pull,
            delayNanoseconds: 0
        ))
        #expect(CommitRemoteSyncRules.isCredentialErrorDescription("Authentication failed"))
        #expect(CommitRemoteSyncRules.isCredentialErrorDescription("HTTP 403 Forbidden"))
        #expect(CommitRemoteSyncRules.isCredentialErrorDescription("network timed out") == false)
        #expect(CommitRemoteSyncRules.isCredentialError(
            NSError(domain: "test", code: 1),
            isAuthenticationError: { _ in true }
        ))
        #expect(CommitRemoteSyncRules.isCredentialError(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP 403 Forbidden"]),
            isAuthenticationError: { _ in false }
        ))
        #expect(CommitRemoteSyncRules.isCredentialError(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "network timed out"]),
            isAuthenticationError: { _ in false }
        ) == false)
        #expect(CommitRemoteSyncRules.isCredentialError(kind: .authentication, description: "network timed out"))
        #expect(CommitRemoteSyncRules.isCredentialError(kind: .other, description: "HTTP 403 Forbidden"))
        #expect(CommitRemoteSyncRules.isCredentialError(kind: .network, description: "network timed out") == false)
        #expect(CommitRemoteSyncRules.retryStatus(attempt: 1, totalAttempts: 2).contains("1/2"))
        #expect(CommitRemoteSyncRules.pushRetryAttempts(delays: [10, 20]).map(\.attempt) == [1, 2])
        #expect(CommitRemoteSyncRules.pushRetryAttempts(delays: [10, 20]).map(\.totalAttempts) == [2, 2])
        #expect(CommitRemoteSyncRules.pushRetryAttempts(delays: [10, 20]).map(\.delayNanoseconds) == [10, 20])
        #expect(CommitRemoteSyncRules.pushRetryAttempts(delays: [10]).first?.statusText.contains("1/1") == true)
        #expect(CommitRemoteSyncRules.pushErrorClassification(
            error: NSError(domain: "network", code: 1),
            isNetworkError: { ($0 as NSError).domain == "network" },
            isAuthenticationError: { _ in false },
            isKnownPushError: { _ in true }
        ) == .init(isNetworkError: true, isAuthenticationError: false, isRetryablePushError: true))
        #expect(CommitRemoteSyncRules.remoteErrorKind(
            isNetworkError: true,
            isAuthenticationError: true,
            isKnownError: true
        ) == .network)
        #expect(CommitRemoteSyncRules.remoteErrorKind(
            isNetworkError: false,
            isAuthenticationError: true,
            isKnownError: true
        ) == .authentication)
        #expect(CommitRemoteSyncRules.remoteErrorKind(
            isNetworkError: false,
            isAuthenticationError: false,
            isKnownError: true
        ) == .known)
        #expect(CommitRemoteSyncRules.remoteErrorKind(
            isNetworkError: false,
            isAuthenticationError: false,
            isKnownError: false
        ) == .other)
        #expect(CommitRemoteSyncRules.pushErrorClassification(kind: .network) == .init(
            isNetworkError: true,
            isAuthenticationError: false,
            isRetryablePushError: true
        ))
        #expect(CommitRemoteSyncRules.pushErrorClassification(kind: .authentication) == .init(
            isNetworkError: false,
            isAuthenticationError: true,
            isRetryablePushError: true
        ))
        #expect(CommitRemoteSyncRules.pushErrorClassification(kind: .known) == .init(
            isNetworkError: false,
            isAuthenticationError: false,
            isRetryablePushError: true
        ))
        #expect(CommitRemoteSyncRules.pushErrorClassification(kind: .other) == .init(
            isNetworkError: false,
            isAuthenticationError: false,
            isRetryablePushError: false
        ))
        #expect(CommitRemoteSyncRules.pushNetworkFallbackAction(isGitCLIAvailable: true) == .systemGit(
            statusText: CommitRemoteSyncRules.activityStatus(.pushingViaSystemGit)
        ))
        #expect(CommitRemoteSyncRules.pushNetworkFallbackAction(isGitCLIAvailable: false) == .showFallback)
        #expect(CommitRemoteSyncRules.repositoryURL(projectPath: "/repo").path == "/repo")
        var fallbackOperations: [String] = []
        let fallbackSucceeded = await CommitRemoteSyncRules.performPushNetworkFallbackAction(
            .systemGit(statusText: "system"),
            setStatus: { fallbackOperations.append("status:\($0)") },
            runSystemGit: { fallbackOperations.append("systemGit") },
            onSystemGitFailure: { _ in fallbackOperations.append("failed") }
        )
        #expect(fallbackSucceeded)
        let fallbackUnavailable = await CommitRemoteSyncRules.performPushNetworkFallbackAction(
            .showFallback,
            setStatus: { fallbackOperations.append("status:\($0)") },
            runSystemGit: { fallbackOperations.append("systemGit") },
            onSystemGitFailure: { _ in fallbackOperations.append("failed") }
        )
        #expect(fallbackUnavailable == false)
        let fallbackFailed = await CommitRemoteSyncRules.performPushNetworkFallbackAction(
            .systemGit(statusText: "retry"),
            setStatus: { fallbackOperations.append("status:\($0)") },
            runSystemGit: {
                throw NSError(domain: "test", code: 1)
            },
            onSystemGitFailure: { _ in fallbackOperations.append("failed") }
        )
        #expect(fallbackFailed == false)
        #expect(fallbackOperations == ["status:system", "systemGit", "status:retry", "failed"])
        fallbackOperations.removeAll()
        let systemGitFallbackSucceeded = await CommitRemoteSyncRules.performSystemGitPushFallback(
            isGitCLIAvailable: true,
            setStatus: { fallbackOperations.append("status:\($0)") },
            runSystemGit: { fallbackOperations.append("systemGit") },
            onSystemGitFailure: { _ in fallbackOperations.append("failed") }
        )
        #expect(systemGitFallbackSucceeded)
        let systemGitFallbackUnavailable = await CommitRemoteSyncRules.performSystemGitPushFallback(
            isGitCLIAvailable: false,
            setStatus: { fallbackOperations.append("status:\($0)") },
            runSystemGit: { fallbackOperations.append("systemGit") },
            onSystemGitFailure: { _ in fallbackOperations.append("failed") }
        )
        #expect(systemGitFallbackUnavailable == false)
        #expect(fallbackOperations == [
            "status:\(CommitRemoteSyncRules.activityStatus(.pushingViaSystemGit))",
            "systemGit",
        ])
        #expect(CommitRemoteSyncRules.workingStatePresentationState(
            changedFileCount: 0,
            unpulledCount: 0,
            isSelected: true,
            isRefreshing: true,
            isPulling: false,
            isPushing: false
        ).trailingAction == .refreshing)
        #expect(CommitRemoteSyncRules.workingStatePresentationState(
            changedFileCount: 0,
            unpulledCount: 2,
            isSelected: false,
            isRefreshing: false,
            isPulling: true,
            isPushing: false
        ) == .init(
            changedFileCount: 0,
            unpulledCount: 2,
            isSelected: false,
            isPulling: true,
            isPushing: false,
            trailingAction: .pull
        ))
        #expect(CommitRemoteSyncRules.workingStatePresentationState(
            changedFileCount: 3,
            unpulledCount: 0,
            isSelected: true,
            isRefreshing: false,
            isPulling: false,
            isPushing: true
        ).trailingAction == .push)
        #expect(CommitRemoteSyncRules.workingStatePresentationState(
            changedFileCount: 3,
            unpulledCount: 1,
            isSelected: false,
            isRefreshing: false,
            isPulling: false,
            isPushing: false
        ).trailingAction == .none)
        #expect(CommitRemoteSyncRules.isWorkingStateSelected(hasSelectedCommit: false))
        #expect(CommitRemoteSyncRules.isWorkingStateSelected(hasSelectedCommit: true) == false)
        #expect(CommitRemoteSyncRules.isWorkingStateSelected(selectedCommit: Optional<String>.none))
        #expect(CommitRemoteSyncRules.isWorkingStateSelected(selectedCommit: Optional("commit")) == false)
        #expect(CommitRemoteSyncRules.selectedCommitAfterWorkingStateTap(current: Optional("commit")) == nil)
        #expect(CommitRemoteSyncRules.selectedCommitAfterWorkingStateTap(current: Optional<String>.none) == nil)
        var requiredRemoteProjectEvents: [String] = []
        #expect(CommitRemoteSyncRules.performRequiredProject(
            Optional<String>.none,
            logMissing: { requiredRemoteProjectEvents.append("missing") },
            perform: { requiredRemoteProjectEvents.append("project:\($0)") }
        ) == false)
        #expect(CommitRemoteSyncRules.performRequiredProject(
            Optional("repo"),
            logMissing: { requiredRemoteProjectEvents.append("missing") },
            perform: { requiredRemoteProjectEvents.append("project:\($0)") }
        ))
        #expect(requiredRemoteProjectEvents == ["missing", "project:repo"])
        var asyncRequiredRemoteProjectEvents: [String] = []
        #expect(await CommitRemoteSyncRules.performRequiredProject(
            Optional<String>.none,
            logMissing: {
                await Task.yield()
                asyncRequiredRemoteProjectEvents.append("missing")
            },
            perform: {
                await Task.yield()
                asyncRequiredRemoteProjectEvents.append("project:\($0)")
            }
        ) == false)
        #expect(await CommitRemoteSyncRules.performRequiredProject(
            Optional("repo"),
            logMissing: {
                await Task.yield()
                asyncRequiredRemoteProjectEvents.append("missing")
            },
            perform: {
                await Task.yield()
                asyncRequiredRemoteProjectEvents.append("project:\($0)")
            }
        ))
        #expect(asyncRequiredRemoteProjectEvents == ["missing", "project:repo"])
        var requiredSyncStatusEvents: [String] = []
        #expect(CommitRemoteSyncRules.performRequiredProjectSyncStatus(
            project: Optional<String>.none,
            projectPath: { $0 },
            logMissing: { requiredSyncStatusEvents.append("missing") },
            perform: { requiredSyncStatusEvents.append("path:\($0.projectPath)") }
        ) == false)
        #expect(CommitRemoteSyncRules.performRequiredProjectSyncStatus(
            project: Optional("/repo"),
            projectPath: { $0 },
            logMissing: { requiredSyncStatusEvents.append("missing") },
            perform: { requiredSyncStatusEvents.append("path:\($0.projectPath)") }
        ))
        #expect(requiredSyncStatusEvents == ["missing", "path:/repo"])
        var requiredSyncStatusCommandEvents: [String] = []
        #expect(CommitRemoteSyncRules.performRequiredProjectSyncStatusCommand(
            project: Optional<String>.none,
            projectPath: { $0 },
            logMissing: { requiredSyncStatusCommandEvents.append("missing") },
            perform: { command in
                requiredSyncStatusCommandEvents.append("\(command.project):\(command.request.projectPath)")
            }
        ) == false)
        #expect(CommitRemoteSyncRules.performRequiredProjectSyncStatusCommand(
            project: Optional("/repo"),
            projectPath: { $0 },
            logMissing: { requiredSyncStatusCommandEvents.append("missing") },
            perform: { command in
                requiredSyncStatusCommandEvents.append("\(command.project):\(command.request.projectPath)")
            }
        ))
        #expect(requiredSyncStatusCommandEvents == ["missing", "/repo:/repo"])
        var requiredRemoteOperationEvents: [String] = []
        #expect(CommitRemoteSyncRules.performRequiredProjectRemoteOperation(
            project: Optional<String>.none,
            projectPath: { $0 },
            operation: .pull,
            logMissing: { requiredRemoteOperationEvents.append("missing") },
            perform: { requiredRemoteOperationEvents.append("\($0.operation):\($0.projectPath)") }
        ) == false)
        #expect(CommitRemoteSyncRules.performRequiredProjectRemoteOperation(
            project: Optional("/repo"),
            projectPath: { $0 },
            operation: .push,
            logMissing: { requiredRemoteOperationEvents.append("missing") },
            perform: { requiredRemoteOperationEvents.append("\($0.operation):\($0.projectPath)") }
        ))
        #expect(requiredRemoteOperationEvents == ["missing", "push:/repo"])
        var requiredRemoteOperationCommandEvents: [String] = []
        #expect(CommitRemoteSyncRules.performRequiredProjectRemoteOperationCommand(
            project: Optional<String>.none,
            projectPath: { $0 },
            operation: .pull,
            logMissing: { requiredRemoteOperationCommandEvents.append("missing") },
            perform: { command in
                requiredRemoteOperationCommandEvents.append("\(command.project):\(command.request.operation):\(command.request.projectPath)")
            }
        ) == false)
        #expect(CommitRemoteSyncRules.performRequiredProjectRemoteOperationCommand(
            project: Optional("/repo"),
            projectPath: { $0 },
            operation: .push,
            logMissing: { requiredRemoteOperationCommandEvents.append("missing") },
            perform: { command in
                requiredRemoteOperationCommandEvents.append("\(command.project):\(command.request.operation):\(command.request.projectPath)")
            }
        ))
        #expect(requiredRemoteOperationCommandEvents == ["missing", "/repo:push:/repo"])
        #expect(CommitRemoteSyncRules.activityStatus(.refreshingFiles).isEmpty == false)
        #expect(CommitRemoteSyncRules.activityStatus(.checkingRemoteStatus).isEmpty == false)
        #expect(CommitRemoteSyncRules.activityStatus(.pulling).isEmpty == false)
        #expect(CommitRemoteSyncRules.activityStatus(.pushing).isEmpty == false)
        #expect(CommitRemoteSyncRules.activityStatus(.pushingViaSystemGit).isEmpty == false)
        #expect(CommitRemoteSyncRules.RetryOperation.pull != .push)
        #expect(CommitRemoteSyncRules.changedFileRefreshStartState().isRefreshing)
        #expect(CommitRemoteSyncRules.changedFileRefreshStartState().statusText?.isEmpty == false)
        #expect(CommitRemoteSyncRules.changedFileRefreshFinishedState() == .init(
            statusText: nil,
            isRefreshing: false
        ))
        var changedFileStatuses: [String?] = []
        var changedFileRefreshing: Bool?
        CommitRemoteSyncRules.performChangedFileRefreshState(
            CommitRemoteSyncRules.changedFileRefreshStartState(),
            setStatus: { changedFileStatuses.append($0) },
            setRefreshing: { changedFileRefreshing = $0 }
        )
        #expect(changedFileStatuses.first??.isEmpty == false)
        #expect(changedFileRefreshing == true)
        var appliedChangedFileCount = -1
        var appliedCleanStates: [Bool] = []
        CommitRemoteSyncRules.performChangedFileCountResult(
            0,
            setChangedFileCount: { appliedChangedFileCount = $0 },
            updateCleanState: { appliedCleanStates.append($0) }
        )
        CommitRemoteSyncRules.performChangedFileCountResult(
            2,
            setChangedFileCount: { appliedChangedFileCount = $0 },
            updateCleanState: { appliedCleanStates.append($0) }
        )
        #expect(appliedChangedFileCount == 2)
        #expect(appliedCleanStates == [true, false])
        var changedFileLoadEvents: [String] = []
        await CommitRemoteSyncRules.performChangedFileCountLoad(
            loadCount: {
                changedFileLoadEvents.append("load")
                return 2
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(changedFileLoadEvents == ["load", "count:2", "finished:false"])
        changedFileLoadEvents = []
        await CommitRemoteSyncRules.performStartedChangedFileCountLoad(
            applyStartState: { changedFileLoadEvents.append("start:\($0.isRefreshing)") },
            loadCount: {
                changedFileLoadEvents.append("load")
                return 3
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(changedFileLoadEvents == ["start:true", "load", "count:3", "finished:false"])
        changedFileLoadEvents = []
        #expect(await CommitRemoteSyncRules.performRequiredProjectStartedChangedFileCountLoad(
            project: Optional<String>.none,
            logMissing: { changedFileLoadEvents.append("missing") },
            applyStartState: { changedFileLoadEvents.append("start:\($0.isRefreshing)") },
            loadCount: { project in
                changedFileLoadEvents.append("load:\(project)")
                return 4
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        ) == false)
        #expect(await CommitRemoteSyncRules.performRequiredProjectStartedChangedFileCountLoad(
            project: Optional("repo"),
            logMissing: { changedFileLoadEvents.append("missing") },
            applyStartState: { changedFileLoadEvents.append("start:\($0.isRefreshing)") },
            loadCount: { project in
                changedFileLoadEvents.append("load:\(project)")
                return 4
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        ))
        #expect(changedFileLoadEvents == ["missing", "start:true", "load:repo", "count:4", "finished:false"])
        changedFileLoadEvents = []
        #expect(await CommitRemoteSyncRules.performRequiredProjectStartedChangedFileCountLoadCommand(
            project: Optional<String>.none,
            logMissing: { changedFileLoadEvents.append("missing") },
            applyStartState: { changedFileLoadEvents.append("start:\($0.isRefreshing)") },
            loadCount: { request in
                changedFileLoadEvents.append("load:\(request.project)")
                return 5
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        ) == false)
        #expect(await CommitRemoteSyncRules.performRequiredProjectStartedChangedFileCountLoadCommand(
            project: Optional("repo"),
            logMissing: { changedFileLoadEvents.append("missing") },
            applyStartState: { changedFileLoadEvents.append("start:\($0.isRefreshing)") },
            loadCount: { request in
                changedFileLoadEvents.append("load:\(request.project)")
                return 5
            },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        ))
        #expect(changedFileLoadEvents == ["missing", "start:true", "load:repo", "count:5", "finished:false"])
        enum ChangedFileCountError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "changed files failed"
            }
        }
        changedFileLoadEvents = []
        await CommitRemoteSyncRules.performChangedFileCountLoad(
            loadCount: { throw ChangedFileCountError.failed },
            applyCount: { changedFileLoadEvents.append("count:\($0)") },
            applyFinishedState: { changedFileLoadEvents.append("finished:\($0.isRefreshing)") },
            handleFailure: { changedFileLoadEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(changedFileLoadEvents == ["finished:false", "failure:changed files failed"])
        #expect(CommitRemoteSyncRules.remoteOperationStartState(operation: .pull) == .init(
            statusText: CommitRemoteSyncRules.activityStatus(.pulling),
            isPulling: true,
            isPushing: false,
            refreshesSyncStatus: false
        ))
        #expect(CommitRemoteSyncRules.remoteOperationStartState(operation: .push) == .init(
            statusText: CommitRemoteSyncRules.activityStatus(.pushing),
            isPulling: false,
            isPushing: true,
            refreshesSyncStatus: false
        ))
        #expect(CommitRemoteSyncRules.remoteOperationFinishedState(
            operation: .push,
            succeeded: true
        ) == .init(
            statusText: nil,
            isPulling: false,
            isPushing: false,
            refreshesSyncStatus: true
        ))
        #expect(CommitRemoteSyncRules.remoteOperationFinishedState(
            operation: .pull,
            succeeded: false
        ) == .init(
            statusText: nil,
            isPulling: false,
            isPushing: false,
            refreshesSyncStatus: false
        ))
        var remoteResultStates: [CommitRemoteSyncRules.RemoteOperationState] = []
        var remoteFailures: [CommitRemoteSyncRules.RetryOperation] = []
        CommitRemoteSyncRules.performRemoteOperationResult(
            .success(()),
            operation: .pull,
            applyState: { remoteResultStates.append($0) },
            presentFailure: { _, operation in remoteFailures.append(operation) }
        )
        CommitRemoteSyncRules.performRemoteOperationResult(
            .failure(NSError(domain: "test", code: 1)),
            operation: .push,
            applyState: { remoteResultStates.append($0) },
            presentFailure: { _, operation in remoteFailures.append(operation) }
        )
        #expect(remoteResultStates == [
            CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: true),
            CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false),
        ])
        #expect(remoteFailures == [.push])
        var remoteOperationEvents: [String] = []
        await CommitRemoteSyncRules.performRemoteOperation(
            perform: { remoteOperationEvents.append("perform") },
            logSuccess: { remoteOperationEvents.append("success") },
            logFailure: { remoteOperationEvents.append("failure:\($0.localizedDescription)") },
            applyResult: { result in
                if case .success = result {
                    remoteOperationEvents.append("result:success")
                }
            }
        )
        #expect(remoteOperationEvents == ["perform", "success", "result:success"])
        enum RemoteOperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "remote failed"
            }
        }
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performRemoteOperation(
            perform: { throw RemoteOperationError.failed },
            logSuccess: { remoteOperationEvents.append("success") },
            logFailure: { remoteOperationEvents.append("failure:\($0.localizedDescription)") },
            applyResult: { result in
                if case let .failure(error) = result {
                    remoteOperationEvents.append("result:\(error.localizedDescription)")
                }
            }
        )
        #expect(remoteOperationEvents == ["failure:remote failed", "result:remote failed"])
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperation(
            operation: .pull,
            perform: { remoteOperationEvents.append("perform") },
            logSuccess: { remoteOperationEvents.append("success") },
            logFailure: { remoteOperationEvents.append("failure:\($0.localizedDescription)") },
            applyState: { remoteOperationEvents.append("state:\($0.isPulling):\($0.refreshesSyncStatus)") },
            presentFailure: { _, operation in remoteOperationEvents.append("present:\(operation)") }
        )
        #expect(remoteOperationEvents == [
            "state:true:false",
            "perform",
            "success",
            "state:false:true",
        ])
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performStartedPullOperation(
            pull: { remoteOperationEvents.append("pull") },
            logSuccess: { remoteOperationEvents.append("success") },
            logFailure: { remoteOperationEvents.append("failure:\($0.localizedDescription)") },
            applyState: { remoteOperationEvents.append("state:\($0.isPulling):\($0.refreshesSyncStatus)") },
            presentFailure: { _, operation in remoteOperationEvents.append("present:\(operation)") }
        )
        #expect(remoteOperationEvents == [
            "state:true:false",
            "pull",
            "success",
            "state:false:true",
        ])
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperation(
            operation: .push,
            perform: { throw RemoteOperationError.failed },
            logSuccess: { remoteOperationEvents.append("success") },
            logFailure: { remoteOperationEvents.append("failure:\($0.localizedDescription)") },
            applyState: { remoteOperationEvents.append("state:\($0.isPushing):\($0.refreshesSyncStatus)") },
            presentFailure: { _, operation in remoteOperationEvents.append("present:\(operation)") }
        )
        #expect(remoteOperationEvents == [
            "state:true:false",
            "failure:remote failed",
            "state:false:false",
            "present:push",
        ])
        enum PushOperationTestError: Error, LocalizedError {
            case network
            case retryable
            case other

            var errorDescription: String? {
                switch self {
                case .network: "network"
                case .retryable: "retryable"
                case .other: "other"
                }
            }
        }
        let isNetworkError: (Error) -> Bool = { ($0 as? PushOperationTestError) == .network }
        let isRetryablePushError: (Error) -> Bool = {
            guard let error = $0 as? PushOperationTestError else { return false }
            return error == .network || error == .retryable
        }
        var pushEvents: [String] = []
        var pushAttempts = 0
        await CommitRemoteSyncRules.performPushOperation(
            push: {
                pushAttempts += 1
                if pushAttempts == 1 { throw PushOperationTestError.network }
                if pushAttempts == 2 { throw PushOperationTestError.retryable }
            },
            isNetworkError: isNetworkError,
            isAuthenticationError: { _ in false },
            isRetryablePushError: isRetryablePushError,
            retryAttempts: CommitRemoteSyncRules.pushRetryAttempts(delays: [10, 20]),
            setStatus: { pushEvents.append("status:\($0.contains("/"))") },
            sleep: { pushEvents.append("sleep:\($0)") },
            runNetworkFallback: {
                pushEvents.append("fallback")
                return false
            },
            logSuccess: { pushEvents.append("success:\($0 ?? 0)") },
            logRetryStart: { pushEvents.append("retry-start") },
            logRetryFailure: { pushEvents.append("retry-failure:\($0)") },
            applyState: { pushEvents.append("state:\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("show-fallback") },
            presentFailure: { pushEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(pushEvents == [
            "retry-start",
            "status:true",
            "sleep:10",
            "retry-failure:1",
            "status:true",
            "sleep:20",
            "success:2",
            "state:true",
        ])
        pushEvents = []
        pushAttempts = 0
        await CommitRemoteSyncRules.performStartedPushOperation(
            push: {
                pushAttempts += 1
            },
            isNetworkError: isNetworkError,
            isAuthenticationError: { _ in false },
            isRetryablePushError: isRetryablePushError,
            retryAttempts: CommitRemoteSyncRules.pushRetryAttempts(delays: []),
            setStatus: { pushEvents.append("status:\($0)") },
            sleep: { pushEvents.append("sleep:\($0)") },
            runNetworkFallback: {
                pushEvents.append("fallback")
                return false
            },
            logSuccess: { pushEvents.append("success:\($0 ?? 0)") },
            logRetryStart: { pushEvents.append("retry-start") },
            logRetryFailure: { pushEvents.append("retry-failure:\($0)") },
            applyState: { pushEvents.append("state:\($0.isPushing):\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("show-fallback") },
            presentFailure: { pushEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(pushEvents == [
            "state:true:false",
            "success:0",
            "state:false:true",
        ])
        let remoteCommandHandlers = CommitRemoteSyncRules.RemoteOperationCommandHandlers(
            pull: { remoteOperationEvents.append("command-pull") },
            push: { pushEvents.append("command-push") },
            pushErrorClassification: { error in
                CommitRemoteSyncRules.PushErrorClassification(
                    isNetworkError: isNetworkError(error),
                    isAuthenticationError: false,
                    isRetryablePushError: isRetryablePushError(error)
                )
            },
            runNetworkFallback: {
                pushEvents.append("command-fallback")
                return false
            }
        )
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperationCommand(
            operation: .pull,
            handlers: remoteCommandHandlers,
            setStatus: { remoteOperationEvents.append("status:\($0)") },
            logPullSuccess: { remoteOperationEvents.append("pull-success") },
            logPullFailure: { remoteOperationEvents.append("pull-failure:\($0.localizedDescription)") },
            logPushSuccess: { remoteOperationEvents.append("push-success:\($0 ?? 0)") },
            logPushRetryStart: { remoteOperationEvents.append("retry-start") },
            logPushRetryFailure: { remoteOperationEvents.append("retry-failure:\($0)") },
            applyState: { remoteOperationEvents.append("state:\($0.isPulling):\($0.refreshesSyncStatus)") },
            showNetworkFallback: { remoteOperationEvents.append("show-fallback") },
            presentFailure: { _, operation in remoteOperationEvents.append("present:\(operation)") }
        )
        #expect(remoteOperationEvents == [
            "state:true:false",
            "command-pull",
            "pull-success",
            "state:false:true",
        ])

        pushEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperationCommand(
            operation: .push,
            handlers: remoteCommandHandlers,
            setStatus: { pushEvents.append("status:\($0)") },
            logPullSuccess: { pushEvents.append("pull-success") },
            logPullFailure: { pushEvents.append("pull-failure:\($0.localizedDescription)") },
            logPushSuccess: { pushEvents.append("push-success:\($0 ?? 0)") },
            logPushRetryStart: { pushEvents.append("retry-start") },
            logPushRetryFailure: { pushEvents.append("retry-failure:\($0)") },
            applyState: { pushEvents.append("state:\($0.isPushing):\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("show-fallback") },
            presentFailure: { _, operation in pushEvents.append("present:\(operation)") }
        )
        #expect(pushEvents == [
            "state:true:false",
            "command-push",
            "push-success:0",
            "state:false:true",
        ])
        let projectRemoteCommandHandlers = CommitRemoteSyncRules.ProjectRemoteOperationCommandHandlers<String>(
            pull: { project in remoteOperationEvents.append("project-command-pull:\(project)") },
            push: { project in
                pushEvents.append("project-command-push:\(project)")
                throw PushOperationTestError.network
            },
            pushErrorClassification: { error in
                CommitRemoteSyncRules.PushErrorClassification(
                    isNetworkError: isNetworkError(error),
                    isAuthenticationError: false,
                    isRetryablePushError: isRetryablePushError(error)
                )
            },
            runNetworkFallback: { project, projectPath in
                pushEvents.append("project-command-fallback:\(project):\(projectPath)")
                return false
            }
        )
        remoteOperationEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperationCommand(
            command: .init(
                request: .init(projectPath: "/repo", operation: .pull),
                project: "repo"
            ),
            handlers: projectRemoteCommandHandlers,
            setStatus: { remoteOperationEvents.append("project-status:\($0)") },
            logPullSuccess: { remoteOperationEvents.append("project-pull-success") },
            logPullFailure: { remoteOperationEvents.append("project-pull-failure:\($0.localizedDescription)") },
            logPushSuccess: { remoteOperationEvents.append("project-push-success:\($0 ?? 0)") },
            logPushRetryStart: { remoteOperationEvents.append("project-retry-start") },
            logPushRetryFailure: { remoteOperationEvents.append("project-retry-failure:\($0)") },
            applyState: { remoteOperationEvents.append("project-state:\($0.isPulling):\($0.refreshesSyncStatus)") },
            showNetworkFallback: { remoteOperationEvents.append("project-show-fallback") },
            presentFailure: { _, operation in remoteOperationEvents.append("project-present:\(operation)") }
        )
        #expect(remoteOperationEvents == [
            "project-state:true:false",
            "project-command-pull:repo",
            "project-pull-success",
            "project-state:false:true",
        ])
        pushEvents = []
        await CommitRemoteSyncRules.performStartedRemoteOperationCommand(
            command: .init(
                request: .init(projectPath: "/repo", operation: .push),
                project: "repo"
            ),
            handlers: projectRemoteCommandHandlers,
            setStatus: { pushEvents.append("project-status:\($0)") },
            retryAttempts: [],
            sleep: { pushEvents.append("project-sleep:\($0)") },
            logPullSuccess: { pushEvents.append("project-pull-success") },
            logPullFailure: { pushEvents.append("project-pull-failure:\($0.localizedDescription)") },
            logPushSuccess: { pushEvents.append("project-push-success:\($0 ?? 0)") },
            logPushRetryStart: { pushEvents.append("project-retry-start") },
            logPushRetryFailure: { pushEvents.append("project-retry-failure:\($0)") },
            applyState: { pushEvents.append("project-state:\($0.isPushing):\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("project-show-fallback") },
            presentFailure: { _, operation in pushEvents.append("project-present:\(operation)") }
        )
        #expect(pushEvents.suffix(3) == [
            "project-command-fallback:repo:/repo",
            "project-state:false:false",
            "project-show-fallback",
        ])
        pushEvents = []
        await CommitRemoteSyncRules.performPushOperation(
            push: { throw PushOperationTestError.network },
            isNetworkError: isNetworkError,
            isAuthenticationError: { _ in false },
            isRetryablePushError: isRetryablePushError,
            retryAttempts: [],
            setStatus: { pushEvents.append("status:\($0)") },
            sleep: { _ in pushEvents.append("sleep") },
            runNetworkFallback: {
                pushEvents.append("fallback")
                return false
            },
            logSuccess: { pushEvents.append("success:\($0 ?? 0)") },
            logRetryStart: { pushEvents.append("retry-start") },
            logRetryFailure: { pushEvents.append("retry-failure:\($0)") },
            applyState: { pushEvents.append("state:\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("show-fallback") },
            presentFailure: { pushEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(pushEvents == ["retry-start", "fallback", "state:false", "show-fallback"])
        pushEvents = []
        await CommitRemoteSyncRules.performPushOperation(
            push: { throw PushOperationTestError.other },
            isNetworkError: isNetworkError,
            isAuthenticationError: { _ in false },
            isRetryablePushError: isRetryablePushError,
            retryAttempts: [],
            setStatus: { pushEvents.append("status:\($0)") },
            sleep: { _ in pushEvents.append("sleep") },
            runNetworkFallback: {
                pushEvents.append("fallback")
                return true
            },
            logSuccess: { pushEvents.append("success:\($0 ?? 0)") },
            logRetryStart: { pushEvents.append("retry-start") },
            logRetryFailure: { pushEvents.append("retry-failure:\($0)") },
            applyState: { pushEvents.append("state:\($0.refreshesSyncStatus)") },
            showNetworkFallback: { pushEvents.append("show-fallback") },
            presentFailure: { pushEvents.append("failure:\($0.localizedDescription)") }
        )
        #expect(pushEvents == ["state:false", "failure:other"])
        var remoteStatePulling: Bool?
        var remoteStatePushing: Bool?
        var remoteStateStatuses: [String?] = []
        var remoteStateRefreshCount = 0
        CommitRemoteSyncRules.performRemoteOperationState(
            CommitRemoteSyncRules.remoteOperationStartState(operation: .pull),
            setPulling: { remoteStatePulling = $0 },
            setPushing: { remoteStatePushing = $0 },
            setStatus: { remoteStateStatuses.append($0) },
            refreshSyncStatus: { remoteStateRefreshCount += 1 }
        )
        CommitRemoteSyncRules.performRemoteOperationState(
            CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: true),
            setPulling: { remoteStatePulling = $0 },
            setPushing: { remoteStatePushing = $0 },
            setStatus: { remoteStateStatuses.append($0) },
            refreshSyncStatus: { remoteStateRefreshCount += 1 }
        )
        #expect(remoteStatePulling == false)
        #expect(remoteStatePushing == false)
        #expect(remoteStateStatuses.count == 2)
        #expect(remoteStateStatuses.first??.isEmpty == false)
        #expect(remoteStateStatuses.last! == nil)
        #expect(remoteStateRefreshCount == 1)
        #expect(CommitRemoteSyncRules.syncStatusRefreshStartState() == .init(
            statusText: CommitRemoteSyncRules.activityStatus(.checkingRemoteStatus),
            isSyncLoading: true
        ))
        #expect(CommitRemoteSyncRules.syncStatusRefreshFinishedState() == .init(
            statusText: nil,
            isSyncLoading: false
        ))
        var syncStatuses: [String?] = []
        var syncLoading: Bool?
        CommitRemoteSyncRules.performSyncStatusRefreshState(
            CommitRemoteSyncRules.syncStatusRefreshStartState(),
            setLoading: { syncLoading = $0 },
            setStatus: { syncStatuses.append($0) }
        )
        #expect(syncLoading == true)
        #expect(syncStatuses.first??.isEmpty == false)
        #expect(CommitRemoteSyncRules.syncStatusResultState(
            unpushedCount: 4,
            unpulledCount: 2
        ) == .init(
            unpushedCount: 4,
            unpulledCount: 2,
            refreshState: CommitRemoteSyncRules.syncStatusRefreshFinishedState()
        ))
        var appliedUnpushedCount = -1
        var appliedUnpulledCount = -1
        var appliedSyncRefreshStates: [CommitRemoteSyncRules.SyncStatusRefreshState] = []
        CommitRemoteSyncRules.performSyncStatusResultState(
            CommitRemoteSyncRules.syncStatusResultState(
                unpushedCount: 3,
                unpulledCount: 4
            ),
            setUnpushedCount: { appliedUnpushedCount = $0 },
            setUnpulledCount: { appliedUnpulledCount = $0 },
            applyRefreshState: { appliedSyncRefreshStates.append($0) }
        )
        #expect(appliedUnpushedCount == 3)
        #expect(appliedUnpulledCount == 4)
        #expect(appliedSyncRefreshStates == [CommitRemoteSyncRules.syncStatusRefreshFinishedState()])
        #expect(try await CommitRemoteSyncRules.unpushedCommitCount(
            loadUnpushedCommits: { ["a", "b", "c"] }
        ) == 3)
        var syncLoadEvents: [String] = []
        await CommitRemoteSyncRules.performSyncStatusLoad(
            loadUnpushedCount: {
                syncLoadEvents.append("load-unpushed")
                return 3
            },
            loadUnpulledCount: {
                syncLoadEvents.append("load-unpulled")
                return 1
            },
            handleUnpushedFailure: { syncLoadEvents.append("unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("clear") },
            sleep: { _ in syncLoadEvents.append("sleep") }
        )
        #expect(syncLoadEvents == [
            "load-unpushed",
            "load-unpulled",
            "result:3:1",
            "sleep",
            "clear",
        ])
        syncLoadEvents = []
        await CommitRemoteSyncRules.performSyncStatusLoad(
            loadUnpushedCommits: {
                syncLoadEvents.append("load-unpushed-commits")
                return ["a", "b"]
            },
            loadUnpulledCount: {
                syncLoadEvents.append("load-unpulled")
                return 4
            },
            handleUnpushedFailure: { syncLoadEvents.append("unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("clear") },
            sleep: { _ in syncLoadEvents.append("sleep") }
        )
        #expect(syncLoadEvents == [
            "load-unpushed-commits",
            "load-unpulled",
            "result:2:4",
            "sleep",
            "clear",
        ])
        syncLoadEvents = []
        await CommitRemoteSyncRules.performStartedSyncStatusLoad(
            applyStartState: { state in syncLoadEvents.append("start:\(state.isSyncLoading)") },
            loadUnpushedCommits: {
                syncLoadEvents.append("load-unpushed-commits")
                return ["a"]
            },
            loadUnpulledCount: {
                syncLoadEvents.append("load-unpulled")
                return 5
            },
            handleUnpushedFailure: { syncLoadEvents.append("unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("clear") },
            sleep: { _ in syncLoadEvents.append("sleep") }
        )
        #expect(syncLoadEvents == [
            "start:true",
            "load-unpushed-commits",
            "load-unpulled",
            "result:1:5",
            "sleep",
            "clear",
        ])
        let syncStatusHandlers = CommitRemoteSyncRules.SyncStatusLoadHandlers<String>(
            loadUnpushedCommits: {
                syncLoadEvents.append("handler-load-unpushed")
                return ["a", "b", "c", "d"]
            },
            loadUnpulledCount: {
                syncLoadEvents.append("handler-load-unpulled")
                return 6
            }
        )
        syncLoadEvents = []
        await CommitRemoteSyncRules.performStartedSyncStatusLoad(
            applyStartState: { state in syncLoadEvents.append("handler-start:\(state.isSyncLoading)") },
            handlers: syncStatusHandlers,
            handleUnpushedFailure: { syncLoadEvents.append("handler-unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("handler-unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("handler-result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("handler-clear") },
            sleep: { _ in syncLoadEvents.append("handler-sleep") }
        )
        #expect(syncLoadEvents == [
            "handler-start:true",
            "handler-load-unpushed",
            "handler-load-unpulled",
            "handler-result:4:6",
            "handler-sleep",
            "handler-clear",
        ])
        let projectSyncStatusHandlers = CommitRemoteSyncRules.ProjectSyncStatusLoadHandlers<String, String>(
            loadUnpushedCommits: { project in
                syncLoadEvents.append("project-handler-load-unpushed:\(project)")
                return ["a", "b", "c"]
            },
            loadUnpulledCount: { project in
                syncLoadEvents.append("project-handler-load-unpulled:\(project)")
                return 7
            }
        )
        let syncStatusCommand = CommitRemoteSyncRules.ProjectSyncStatusRequest(
            request: .init(projectPath: "/repo"),
            project: "repo"
        )
        syncLoadEvents = []
        await CommitRemoteSyncRules.performStartedSyncStatusLoad(
            command: syncStatusCommand,
            applyStartState: { state in syncLoadEvents.append("project-handler-start:\(state.isSyncLoading)") },
            handlers: projectSyncStatusHandlers,
            handleUnpushedFailure: { syncLoadEvents.append("project-handler-unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("project-handler-unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("project-handler-result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("project-handler-clear") },
            sleep: { _ in syncLoadEvents.append("project-handler-sleep") }
        )
        #expect(syncLoadEvents == [
            "project-handler-start:true",
            "project-handler-load-unpushed:repo",
            "project-handler-load-unpulled:repo",
            "project-handler-result:3:7",
            "project-handler-sleep",
            "project-handler-clear",
        ])
        enum SyncStatusError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "sync failed"
            }
        }
        syncLoadEvents = []
        await CommitRemoteSyncRules.performSyncStatusLoad(
            loadUnpushedCount: { throw SyncStatusError.failed },
            loadUnpulledCount: { throw SyncStatusError.failed },
            handleUnpushedFailure: { syncLoadEvents.append("unpushed-failure:\($0.localizedDescription)") },
            handleUnpulledFailure: { syncLoadEvents.append("unpulled-failure:\($0.localizedDescription)") },
            applyResult: { state in syncLoadEvents.append("result:\(state.unpushedCount):\(state.unpulledCount)") },
            clearStatus: { syncLoadEvents.append("clear") },
            sleep: { _ in syncLoadEvents.append("sleep") }
        )
        #expect(syncLoadEvents == [
            "unpushed-failure:sync failed",
            "unpulled-failure:sync failed",
            "result:0:0",
            "sleep",
            "clear",
        ])
        #expect(CommitRemoteSyncRules.credentialPromptState(
            isCredentialError: true,
            host: "github.com",
            operation: .push
        ) == .init(
            showsPrompt: true,
            host: "github.com",
            retryOperation: .push
        ))
        #expect(CommitRemoteSyncRules.credentialPromptState(
            isCredentialError: false,
            host: "github.com",
            operation: .push
        ) == nil)
        #expect(CommitRemoteSyncRules.credentialPromptState(
            isCredentialError: true,
            host: nil,
            operation: .pull
        ) == .init(
            showsPrompt: true,
            host: CommitRemoteSyncRules.defaultCredentialHost,
            retryOperation: .pull
        ))
        var appliedCredentialPrompt = false
        var appliedCredentialHost = ""
        var appliedCredentialRetryOperation: CommitRemoteSyncRules.RetryOperation?
        CommitRemoteSyncRules.performCredentialPromptState(
            CommitRemoteSyncRules.credentialPromptState(
                isCredentialError: true,
                host: "github.com",
                operation: .push
            )!,
            setShowsPrompt: { appliedCredentialPrompt = $0 },
            setHost: { appliedCredentialHost = $0 },
            setRetryOperation: { appliedCredentialRetryOperation = $0 }
        )
        #expect(appliedCredentialPrompt)
        #expect(appliedCredentialHost == "github.com")
        #expect(appliedCredentialRetryOperation == .push)
        #expect(CommitRemoteSyncRules.sshHelpState(
            isSSHAuthenticationError: true,
            remoteURL: "git@github.com:owner/repo.git",
            errorMessage: "host key failed",
            operation: .pull
        ) == .init(
            showsPrompt: true,
            remoteURL: "git@github.com:owner/repo.git",
            errorMessage: "host key failed",
            retryOperation: .pull
        ))
        #expect(CommitRemoteSyncRules.sshHelpState(
            isSSHAuthenticationError: false,
            remoteURL: nil,
            errorMessage: "network failed",
            operation: .push
        ) == nil)
        var appliedSSHHelpPrompt = false
        var appliedSSHHelpRemoteURL: String?
        var appliedSSHHelpErrorMessage: String?
        var appliedSSHHelpRetryOperation: CommitRemoteSyncRules.RetryOperation?
        CommitRemoteSyncRules.performSSHHelpState(
            CommitRemoteSyncRules.sshHelpState(
                isSSHAuthenticationError: true,
                remoteURL: "git@github.com:owner/repo.git",
                errorMessage: "host key failed",
                operation: .pull
            )!,
            setShowsPrompt: { appliedSSHHelpPrompt = $0 },
            setRemoteURL: { appliedSSHHelpRemoteURL = $0 },
            setErrorMessage: { appliedSSHHelpErrorMessage = $0 },
            setRetryOperation: { appliedSSHHelpRetryOperation = $0 }
        )
        #expect(appliedSSHHelpPrompt)
        #expect(appliedSSHHelpRemoteURL == "git@github.com:owner/repo.git")
        #expect(appliedSSHHelpErrorMessage == "host key failed")
        #expect(appliedSSHHelpRetryOperation == .pull)
        #expect(CommitRemoteSyncRules.isSSHAuthenticationErrorDescription(
            "git@github.com: Permission denied (publickey)."
        ))
        #expect(CommitRemoteSyncRules.isSSHAuthenticationErrorDescription(
            "Host key verification failed."
        ))
        #expect(CommitRemoteSyncRules.isSSHAuthenticationErrorDescription("network failed") == false)
        let credentialState = CommitRemoteSyncRules.credentialPromptState(
            isCredentialError: true,
            host: "github.com",
            operation: .push
        )
        let sshHelpState = CommitRemoteSyncRules.sshHelpState(
            isSSHAuthenticationError: true,
            remoteURL: "git@github.com:owner/repo.git",
            errorMessage: "host key failed",
            operation: .pull
        )
        #expect(CommitRemoteSyncRules.remoteFailurePresentation(
            credentialState: credentialState,
            sshHelpState: sshHelpState
        ) == .credential(credentialState!))
        #expect(CommitRemoteSyncRules.remoteFailurePresentation(
            credentialState: nil,
            sshHelpState: sshHelpState
        ) == .sshHelp(sshHelpState!))
        #expect(CommitRemoteSyncRules.remoteFailurePresentation(
            credentialState: nil,
            sshHelpState: nil
        ) == .alert)
        #expect(CommitRemoteSyncRules.remoteFailurePresentation(
            errorDescription: "authentication failed",
            isCredentialError: true,
            credentialHost: nil,
            sshRemoteURL: "git@github.com:owner/repo.git",
            operation: .push
        ) == .credential(.init(
            showsPrompt: true,
            host: CommitRemoteSyncRules.defaultCredentialHost,
            retryOperation: .push
        )))
        #expect(CommitRemoteSyncRules.remoteFailurePresentation(
            errorDescription: "git@github.com: Permission denied (publickey).",
            isCredentialError: false,
            credentialHost: nil,
            sshRemoteURL: "git@github.com:owner/repo.git",
            operation: .pull
        ) == .sshHelp(.init(
            showsPrompt: true,
            remoteURL: "git@github.com:owner/repo.git",
            errorMessage: "git@github.com: Permission denied (publickey).",
            retryOperation: .pull
        )))
        var failurePresentations: [String] = []
        CommitRemoteSyncRules.performRemoteFailurePresentation(
            .credential(credentialState!),
            showCredentialPrompt: { _ in failurePresentations.append("credential") },
            showSSHHelp: { _ in failurePresentations.append("ssh") },
            showAlert: { failurePresentations.append("alert") }
        )
        CommitRemoteSyncRules.performRemoteFailurePresentation(
            .sshHelp(sshHelpState!),
            showCredentialPrompt: { _ in failurePresentations.append("credential") },
            showSSHHelp: { _ in failurePresentations.append("ssh") },
            showAlert: { failurePresentations.append("alert") }
        )
        CommitRemoteSyncRules.performRemoteFailurePresentation(
            .alert,
            showCredentialPrompt: { _ in failurePresentations.append("credential") },
            showSSHHelp: { _ in failurePresentations.append("ssh") },
            showAlert: { failurePresentations.append("alert") }
        )
        #expect(failurePresentations == ["credential", "ssh", "alert"])
        #expect(CommitRemoteSyncRules.credentialPromptDismissState(operation: .push) == .init(
            showsPrompt: false,
            retryAction: .init(
                operation: .push,
                delayNanoseconds: CommitRemoteSyncRules.credentialRetryDelayNanoseconds
            )
        ))
        #expect(CommitRemoteSyncRules.sshHelpDismissState(operation: nil) == .init(
            showsPrompt: false,
            retryAction: nil
        ))
        #expect(CommitRemoteSyncRules.retryPromptDismissState(
            for: .credential,
            operation: .pull
        ) == .init(
            showsPrompt: false,
            retryAction: .init(
                operation: .pull,
                delayNanoseconds: CommitRemoteSyncRules.credentialRetryDelayNanoseconds
            )
        ))
        #expect(CommitRemoteSyncRules.retryPromptDismissState(
            for: .sshHelp,
            operation: .push
        ) == .init(
            showsPrompt: false,
            retryAction: .init(operation: .push, delayNanoseconds: 0)
        ))
        #expect(CommitRemoteSyncRules.retryPromptApplicationState(
            state: .init(
                showsPrompt: false,
                retryAction: .init(
                    operation: .pull,
                    delayNanoseconds: CommitRemoteSyncRules.credentialRetryDelayNanoseconds
                )
            ),
            prompt: .credential
        ) == .init(
            showsCredentialPrompt: false,
            showsSSHHelp: nil,
            retryAction: .init(
                operation: .pull,
                delayNanoseconds: CommitRemoteSyncRules.credentialRetryDelayNanoseconds
            )
        ))
        #expect(CommitRemoteSyncRules.retryPromptApplicationState(
            state: .init(
                showsPrompt: false,
                retryAction: .init(operation: .push, delayNanoseconds: 0)
            ),
            prompt: .sshHelp
        ) == .init(
            showsCredentialPrompt: nil,
            showsSSHHelp: false,
            retryAction: .init(operation: .push, delayNanoseconds: 0)
        ))
        var retryPromptEvents: [String] = []
        CommitRemoteSyncRules.performRetryPromptApplicationState(
            .init(
                showsCredentialPrompt: false,
                showsSSHHelp: nil,
                retryAction: .init(operation: .pull, delayNanoseconds: 10)
            ),
            setCredentialPrompt: { retryPromptEvents.append("credential:\($0)") },
            setSSHHelp: { retryPromptEvents.append("ssh:\($0)") },
            performRetry: { retryPromptEvents.append("retry:\($0.operation)") }
        )
        CommitRemoteSyncRules.performRetryPromptApplicationState(
            .init(
                showsCredentialPrompt: nil,
                showsSSHHelp: false,
                retryAction: .init(operation: .push, delayNanoseconds: 0)
            ),
            setCredentialPrompt: { retryPromptEvents.append("credential:\($0)") },
            setSSHHelp: { retryPromptEvents.append("ssh:\($0)") },
            performRetry: { retryPromptEvents.append("retry:\($0.operation)") }
        )
        #expect(retryPromptEvents == ["credential:false", "retry:pull", "ssh:false", "retry:push"])
        var retryOperations: [String] = []
        CommitRemoteSyncRules.performRetryOperation(
            .push,
            onPush: { retryOperations.append("push") },
            onPull: { retryOperations.append("pull") }
        )
        CommitRemoteSyncRules.performRetryOperation(
            .pull,
            onPush: { retryOperations.append("push") },
            onPull: { retryOperations.append("pull") }
        )
        #expect(retryOperations == ["push", "pull"])
        let delayedRetry = CommitRemoteSyncRules.RetryAction(
            operation: .pull,
            delayNanoseconds: 2_500_000_000
        )
        #expect(CommitRemoteSyncRules.retryDelaySeconds(delayedRetry) == 2.5)
        var retryActionEvents: [String] = []
        CommitRemoteSyncRules.performRetryAction(
            delayedRetry,
            schedule: { delay, action in
                retryActionEvents.append("delay:\(delay)")
                action()
            },
            onPush: { retryActionEvents.append("push") },
            onPull: { retryActionEvents.append("pull") }
        )
        CommitRemoteSyncRules.performRetryAction(
            .init(operation: .push, delayNanoseconds: 0),
            schedule: { delay, action in
                retryActionEvents.append("delay:\(delay)")
                action()
            },
            onPush: { retryActionEvents.append("push") },
            onPull: { retryActionEvents.append("pull") }
        )
        #expect(retryActionEvents == ["delay:2.5", "pull", "delay:0.0", "push"])
        var refreshOperations: [String] = []
        CommitRemoteSyncRules.performWorkingStateRefreshAction(
            .full,
            refreshChangedFiles: { refreshOperations.append("files") },
            refreshSyncStatus: { refreshOperations.append("sync") }
        )
        CommitRemoteSyncRules.performWorkingStateRefreshAction(
            .none,
            refreshChangedFiles: { refreshOperations.append("files") },
            refreshSyncStatus: { refreshOperations.append("sync") }
        )
        CommitRemoteSyncRules.performWorkingStateEvent(.projectDidPush) {
            refreshOperations.append("event:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        CommitRemoteSyncRules.performGitDirectoryChangedWorkingStateEvent(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 },
            didHeadChange: false
        ) {
            refreshOperations.append("gitdir:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        #expect(refreshOperations == [
            "files",
            "sync",
            "event:false:true",
            "gitdir:true:false",
        ])
        var workingStateEvents: [String] = []
        CommitRemoteSyncRules.performWorkingStateAppear(
            performRefreshAction: { workingStateEvents.append("appear:\($0.refreshChangedFiles):\($0.refreshSyncStatus)") },
            startTimer: { workingStateEvents.append("timer:start") }
        )
        CommitRemoteSyncRules.performWorkingStateDisappear {
            workingStateEvents.append("timer:stop")
        }
        var selectedWorkingStateCommit: String? = "abc123"
        CommitRemoteSyncRules.performWorkingStateTap(
            currentCommit: selectedWorkingStateCommit,
            setCommit: { selectedWorkingStateCommit = $0 },
            performRefreshAction: { workingStateEvents.append("tap:\($0.refreshChangedFiles):\($0.refreshSyncStatus)") }
        )
        #expect(selectedWorkingStateCommit == nil)
        CommitRemoteSyncRules.performProjectDidCommit {
            workingStateEvents.append("commit:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        CommitRemoteSyncRules.performProjectDidChange {
            workingStateEvents.append("change:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        CommitRemoteSyncRules.performProjectDidPush {
            workingStateEvents.append("push:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        CommitRemoteSyncRules.performProjectDidPull {
            workingStateEvents.append("pull:\($0.refreshChangedFiles):\($0.refreshSyncStatus)")
        }
        #expect(workingStateEvents == [
            "appear:true:true",
            "timer:start",
            "timer:stop",
            "tap:true:false",
            "commit:true:true",
            "change:true:true",
            "push:false:true",
            "pull:false:true",
        ])
        var delayedRefreshEvents: [String] = []
        await CommitRemoteSyncRules.performDelayedWorkingStateRefreshAction(
            .syncStatusOnly,
            delayNanoseconds: 123,
            sleep: { delayedRefreshEvents.append("sleep:\($0)") },
            performRefreshAction: { delayedRefreshEvents.append("refresh:\($0.refreshSyncStatus)") }
        )
        #expect(delayedRefreshEvents == ["sleep:123", "refresh:true"])
        delayedRefreshEvents = []
        await CommitRemoteSyncRules.performDelayedWorkingStateRefreshAction(
            .changedFilesOnly,
            delayNanoseconds: 456,
            sleep: { _ in throw NSError(domain: "GitOKTests", code: 1) },
            performRefreshAction: { delayedRefreshEvents.append("refresh:\($0.refreshChangedFiles)") }
        )
        #expect(delayedRefreshEvents.isEmpty)
        let fallbackAlertText = CommitRemoteSyncRules.networkFallbackAlertText()
        #expect(fallbackAlertText.title.isEmpty == false)
        #expect(fallbackAlertText.message.isEmpty == false)
        #expect(fallbackAlertText.retryButtonTitle.isEmpty == false)
        #expect(fallbackAlertText.toggleSSHPushButtonTitle.isEmpty == false)
        #expect(fallbackAlertText.cancelButtonTitle.isEmpty == false)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(buttonIndex: 0) == .retry)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(buttonIndex: 1) == .toggleSSH)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(buttonIndex: 2) == .cancel)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(buttonIndex: -1) == .cancel)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(
            response: "first",
            firstButton: "first",
            secondButton: "second"
        ) == .retry)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(
            response: "second",
            firstButton: "first",
            secondButton: "second"
        ) == .toggleSSH)
        #expect(CommitRemoteSyncRules.networkFallbackSelection(
            response: "other",
            firstButton: "first",
            secondButton: "second"
        ) == .cancel)
        #expect(CommitRemoteSyncRules.networkFallbackSelectionState(
            selection: .retry,
            remoteURL: nil,
            fallbackErrorMessage: "failed"
        ) == .init(
            retryAction: .init(operation: .push, delayNanoseconds: 0),
            sshHelpState: nil
        ))
        #expect(CommitRemoteSyncRules.networkFallbackSelectionState(
            selection: .toggleSSH,
            remoteURL: "git@github.com:owner/repo.git",
            fallbackErrorMessage: "failed"
        ) == .init(
            retryAction: nil,
            sshHelpState: .init(
                showsPrompt: true,
                remoteURL: "git@github.com:owner/repo.git",
                errorMessage: "failed",
                retryOperation: .push
            )
        ))
        #expect(CommitRemoteSyncRules.networkFallbackSelectionState(
            selection: .cancel,
            remoteURL: "git@github.com:owner/repo.git",
            fallbackErrorMessage: "failed"
        ) == .init(retryAction: nil, sshHelpState: nil))
        var fallbackSelectionEvents: [String] = []
        CommitRemoteSyncRules.performNetworkFallbackSelectionState(
            .init(retryAction: .init(operation: .push, delayNanoseconds: 0), sshHelpState: nil),
            performRetry: { fallbackSelectionEvents.append("retry:\($0.operation)") },
            showSSHHelp: { _ in fallbackSelectionEvents.append("ssh") }
        )
        CommitRemoteSyncRules.performNetworkFallbackSelectionState(
            .init(
                retryAction: nil,
                sshHelpState: .init(
                    showsPrompt: true,
                    remoteURL: "git@github.com:owner/repo.git",
                    errorMessage: "failed",
                    retryOperation: .push
                )
            ),
            performRetry: { fallbackSelectionEvents.append("retry:\($0.operation)") },
            showSSHHelp: { _ in fallbackSelectionEvents.append("ssh") }
        )
        CommitRemoteSyncRules.performNetworkFallbackSelectionState(
            .init(retryAction: nil, sshHelpState: nil),
            performRetry: { fallbackSelectionEvents.append("retry:\($0.operation)") },
            showSSHHelp: { _ in fallbackSelectionEvents.append("ssh") }
        )
        #expect(fallbackSelectionEvents == ["retry:push", "ssh"])
        let remotes = [
            CommitRemoteSyncRules.RemoteURLs(
                name: "upstream",
                url: "https://example.com/upstream/repo.git",
                fetchURL: nil,
                pushURL: nil
            ),
            CommitRemoteSyncRules.RemoteURLs(
                name: "origin",
                url: "git@github.com:owner/repo.git",
                fetchURL: "https://github.com/owner/repo.git",
                pushURL: nil
            ),
        ]
        #expect(CommitRemoteSyncRules.preferredCandidateURLs(from: remotes) == [
            "https://github.com/owner/repo.git",
            "git@github.com:owner/repo.git",
        ])
        #expect(CommitRemoteSyncRules.credentialHost(from: remotes) == "github.com")
        #expect(CommitRemoteSyncRules.sshRemoteURL(from: remotes) == "git@github.com:owner/repo.git")
        struct RemoteFixture {
            let name: String
            let url: String?
            let fetchURL: String?
            let pushURL: String?
        }
        let remoteFixtures = remotes.map {
            RemoteFixture(name: $0.name, url: $0.url, fetchURL: $0.fetchURL, pushURL: $0.pushURL)
        }
        #expect(CommitRemoteSyncRules.remoteURLs(
            from: remoteFixtures,
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == remotes)
        #expect(CommitRemoteSyncRules.credentialHost(
            loadRemotes: { remoteFixtures },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == "github.com")
        #expect(CommitRemoteSyncRules.sshRemoteURL(
            loadRemotes: { remoteFixtures },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == "git@github.com:owner/repo.git")
        #expect(CommitRemoteSyncRules.remoteAccess(from: remotes) == .init(
            credentialHost: "github.com",
            sshRemoteURL: "git@github.com:owner/repo.git"
        ))
        #expect(CommitRemoteSyncRules.remoteAccess(
            loadRemotes: { remoteFixtures },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == .init(
            credentialHost: "github.com",
            sshRemoteURL: "git@github.com:owner/repo.git"
        ))
        var projectRemoteLoadEvents: [String] = []
        #expect(CommitRemoteSyncRules.projectCredentialHost(
            project: Optional("repo"),
            loadRemotes: { project in
                projectRemoteLoadEvents.append("credential:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == "github.com")
        #expect(CommitRemoteSyncRules.projectSSHRemoteURL(
            project: Optional("repo"),
            loadRemotes: { project in
                projectRemoteLoadEvents.append("ssh:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == "git@github.com:owner/repo.git")
        #expect(CommitRemoteSyncRules.projectRemoteAccess(
            project: Optional("repo"),
            loadRemotes: { project in
                projectRemoteLoadEvents.append("access:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == .init(
            credentialHost: "github.com",
            sshRemoteURL: "git@github.com:owner/repo.git"
        ))
        #expect(projectRemoteLoadEvents == ["credential:repo", "ssh:repo", "access:repo"])
        projectRemoteLoadEvents.removeAll()
        #expect(CommitRemoteSyncRules.projectCredentialHost(
            project: Optional<String>.none,
            loadRemotes: { project in
                projectRemoteLoadEvents.append("credential:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == nil)
        #expect(CommitRemoteSyncRules.projectSSHRemoteURL(
            project: Optional<String>.none,
            loadRemotes: { project in
                projectRemoteLoadEvents.append("ssh:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == nil)
        #expect(CommitRemoteSyncRules.projectRemoteAccess(
            project: Optional<String>.none,
            loadRemotes: { project in
                projectRemoteLoadEvents.append("access:\(project)")
                return remoteFixtures
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == .empty)
        #expect(projectRemoteLoadEvents.isEmpty)
        #expect(CommitRemoteSyncRules.optionalRequiredProjectValue(Optional<String>.none) {
            "project:\($0)"
        } == nil)
        #expect(CommitRemoteSyncRules.optionalRequiredProjectValue(Optional("repo")) {
            "project:\($0)"
        } == "project:repo")
        #expect(CommitRemoteSyncRules.credentialHost(
            loadRemotes: { () throws -> [RemoteFixture] in
                throw NSError(domain: "GitOKTests", code: 1)
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == nil)
        #expect(CommitRemoteSyncRules.remoteAccess(
            loadRemotes: { () throws -> [RemoteFixture] in
                throw NSError(domain: "GitOKTests", code: 1)
            },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
        ) == .empty)
    }

    @Test("commit history list metrics match legacy layout")
    func commitHistoryListMetrics() {
        #expect(CommitHistoryListMetrics.loadingMoreIndicatorHeight == 44)
    }
}
