import Foundation
import KitGit
import LibGit2Swift
import Testing
@testable import PluginGitLibGit2

@Suite("LibGit2 push recovery")
struct LibGit2PushRecoveryTests {
    private let fastPolicy = GitPushRetryPolicy(
        maximumAttempts: 2,
        initialDelay: 0,
        delayMultiplier: 2,
        maximumDelay: 0
    )

    @Test("classifies transport failures as transient")
    func classifiesTransportFailures() {
        #expect(LibGit2PushFailureClassifier.classify(LibGit2Error.networkError(-9806)) == .transient)
        #expect(
            LibGit2PushFailureClassifier.classify(
                LibGit2Error.pushFailed("SecureTransport error: -9806")
            ) == .transient
        )
        #expect(
            LibGit2PushFailureClassifier.classify(
                LibGit2Error.pushFailed("Failed to connect to github.com port 443")
            ) == .transient
        )
    }

    @Test("classifies authentication and business failures")
    func classifiesOtherFailures() {
        #expect(LibGit2PushFailureClassifier.classify(LibGit2Error.authenticationError) == .authentication)
        #expect(
            LibGit2PushFailureClassifier.classify(
                LibGit2Error.pushFailed("Updates were rejected because the remote contains work")
            ) == .permanent
        )
        #expect(
            LibGit2PushFailureClassifier.classify(
                LibGit2Error.noUpstreamConfigured(branch: "dev")
            ) == .permanent
        )
    }

    @Test("builds system Git arguments")
    func buildsSystemGitArguments() {
        #expect(SystemGitPushCommand.branchArguments() == ["push"])
        #expect(
            SystemGitPushCommand.tagArguments(named: "v1.0.0", remote: "origin")
                == ["push", "origin", "refs/tags/v1.0.0:refs/tags/v1.0.0"]
        )
    }

    @Test("falls back to system Git after libgit2 transport failures")
    func fallsBackToSystemGit() throws {
        try #require(GitProcessRunner.isAvailable)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibGit2PushRecoveryTests-\(UUID().uuidString)")
        let remote = root.appendingPathComponent("remote.git")
        let working = root.appendingPathComponent("working")
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try runGit(["init", "--bare", "-q", remote.path], in: root)
        try runGit(["init", "-q", working.path], in: root)
        try runGit(["config", "user.email", "test@example.com"], in: working)
        try runGit(["config", "user.name", "Test"], in: working)
        try runGit(["remote", "add", "origin", remote.path], in: working)
        try Data("first\n".utf8).write(to: working.appendingPathComponent("file.txt"))
        try runGit(["add", "."], in: working)
        try runGit(["commit", "-qm", "first"], in: working)
        try runGit(["push", "-q", "-u", "origin", "HEAD"], in: working)

        try Data("second\n".utf8).write(to: working.appendingPathComponent("file.txt"))
        try runGit(["add", "."], in: working)
        try runGit(["commit", "-qm", "second"], in: working)

        try LibGit2PushRecovery.perform(
            in: working,
            arguments: SystemGitPushCommand.branchArguments(),
            policy: fastPolicy,
            primary: { throw LibGit2Error.networkError(-9806) }
        )

        let branch = try runGit(["rev-parse", "--abbrev-ref", "HEAD"], in: working)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let localTip = try runGit(["rev-parse", "HEAD"], in: working)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let remoteTip = try runGit(["rev-parse", "refs/heads/\(branch)"], in: remote)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(localTip == remoteTip)
    }

    @Test("surfaces guidance when every strategy fails")
    func surfacesGuidanceWhenAllStrategiesFail() throws {
        try #require(GitProcessRunner.isAvailable)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibGit2PushRecoveryTests-\(UUID().uuidString)")
        let remote = root.appendingPathComponent("remote.git")
        let working = root.appendingPathComponent("working")
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try runGit(["init", "--bare", "-q", remote.path], in: root)
        try runGit(["init", "-q", working.path], in: root)
        try runGit(["config", "user.email", "test@example.com"], in: working)
        try runGit(["config", "user.name", "Test"], in: working)
        try runGit(["remote", "add", "origin", remote.path], in: working)
        try Data("only\n".utf8).write(to: working.appendingPathComponent("file.txt"))
        try runGit(["add", "."], in: working)
        try runGit(["commit", "-qm", "only"], in: working)

        do {
            try LibGit2PushRecovery.perform(
                in: working,
                arguments: SystemGitPushCommand.branchArguments(),
                policy: fastPolicy,
                primary: { throw LibGit2Error.networkError(-9806) }
            )
            Issue.record("Expected push recovery to fail")
        } catch let error as PushRecoveryFailure {
            let hint = PluginGitLibGit2.pluginLocalization.string(
                "Check your credentials, proxy or VPN settings, or switch the remote to SSH, then try again."
            )
            #expect(error.localizedDescription.contains(hint))
            #expect(error.localizedDescription.contains("Network error"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @discardableResult
    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        try GitProcessRunner.run(arguments, in: directory)
    }
}
