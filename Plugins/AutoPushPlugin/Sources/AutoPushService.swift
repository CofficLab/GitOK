import Combine
import ProjectRulesKit
import GitCoreKit
import Foundation
import GitOKCoreKit

@MainActor
public final class AutoPushService: ObservableObject {
    public static let shared = AutoPushService()

    public enum PushStatus: Equatable {
        case idle
        case pushing
        case success
        case failed(String)
    }

    public static let checkInterval: TimeInterval = 30

    @Published public private(set) var isPushing = false
    @Published public private(set) var lastPushStatus: PushStatus = .idle
    @Published public private(set) var isTimerRunning = false

    private var timer: Timer?
    private var currentProjectProvider: (@MainActor () -> AutoPushProjectSnapshot?)?

    private init() {}

    public func register(currentProjectProvider: @escaping @MainActor () -> AutoPushProjectSnapshot?) {
        self.currentProjectProvider = currentProjectProvider
        startTimer()
    }

    public func startTimer() {
        guard timer == nil else { return }

        isTimerRunning = true
        Task { await checkAndAutoPushForCurrentProject() }

        timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndAutoPushForCurrentProject()
            }
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    public func checkAndAutoPushForCurrentProject() async {
        guard let snapshot = currentProjectProvider?() else { return }
        await checkAndAutoPush(snapshot: snapshot)
    }

    public func checkAndAutoPush(snapshot: AutoPushProjectSnapshot) async {
        let isEnabled = AutoPushSettingsStore.shared.isAutoPushEnabled(
            for: snapshot.projectPath,
            branchName: snapshot.branchName ?? ""
        )

        let hasRemote = await Task.detached {
            ((try? GitRepositoryCLI(repositoryURL: URL(fileURLWithPath: snapshot.projectPath)).remoteNames()) ?? []).isEmpty == false
        }.value

        switch AutoPushDecision.check(
            currentBranchName: snapshot.branchName,
            isEnabled: isEnabled,
            isGitRepo: snapshot.isGitRepository,
            hasRemote: hasRemote
        ) {
        case let .shouldPush(branchName):
            await performPush(projectPath: snapshot.projectPath, branchName: branchName)
        case .skip:
            break
        }
    }

    public func performPush(projectPath: String, branchName: String) async {
        let executionDecision = AutoPushDecision.execution(
            isAlreadyPushing: isPushing,
            unpushedCommitCount: 1
        )

        guard executionDecision != .skipAlreadyPushing else { return }

        isPushing = true
        lastPushStatus = .pushing
        let repositoryURL = URL(fileURLWithPath: projectPath)

        do {
            let unpushedCommitCount = try await Task.detached(priority: .userInitiated) {
                try GitRepositoryCLI(repositoryURL: repositoryURL).unpushedCommitHashes().count
            }.value

            if AutoPushDecision.execution(isAlreadyPushing: false, unpushedCommitCount: unpushedCommitCount) == .markIdle {
                isPushing = false
                lastPushStatus = .idle
                return
            }

            try await Task.detached(priority: .userInitiated) {
                try GitRepositoryCLI(repositoryURL: repositoryURL).push()
            }.value
            AutoPushSettingsStore.shared.updateLastPushedDate(for: projectPath, branchName: branchName)
            isPushing = false
            lastPushStatus = .success
        } catch {
            isPushing = false
            lastPushStatus = .failed(error.localizedDescription)
        }
    }
}

public struct AutoPushProjectSnapshot: Equatable, Sendable {
    public let projectPath: String
    public let projectTitle: String
    public let branchName: String?
    public let isGitRepository: Bool

    public init(projectPath: String, projectTitle: String, branchName: String?, isGitRepository: Bool) {
        self.projectPath = projectPath
        self.projectTitle = projectTitle
        self.branchName = branchName
        self.isGitRepository = isGitRepository
    }
}
