import Foundation
import Testing
@testable import KitGit

@Suite("GitPushRecovery")
struct GitPushRecoveryTests {
    private struct TestError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private func policy(
        maximumAttempts: Int = 3,
        initialDelay: TimeInterval = 2,
        delayMultiplier: Double = 2
    ) -> GitPushRetryPolicy {
        GitPushRetryPolicy(
            maximumAttempts: maximumAttempts,
            initialDelay: initialDelay,
            delayMultiplier: delayMultiplier,
            maximumDelay: 60
        )
    }

    @Test("retries transient failures with exponential backoff")
    func retriesTransientFailures() throws {
        var primaryAttempts = 0
        var delays: [TimeInterval] = []

        try GitPushRecovery.perform(
            policy: policy(),
            classification: { _ in .transient },
            primary: {
                primaryAttempts += 1
                if primaryAttempts < 3 {
                    throw TestError(message: "SSL handshake failed")
                }
            },
            sleep: { delays.append($0) }
        )

        #expect(primaryAttempts == 3)
        #expect(delays == [2, 4])
    }

    @Test("falls back after transient retries are exhausted")
    func fallsBackAfterTransientRetries() throws {
        var primaryAttempts = 0
        var fallbackAttempts = 0
        var delays: [TimeInterval] = []

        try GitPushRecovery.perform(
            policy: policy(),
            classification: { _ in .transient },
            primary: {
                primaryAttempts += 1
                throw TestError(message: "connection reset")
            },
            fallback: { fallbackAttempts += 1 },
            sleep: { delays.append($0) }
        )

        #expect(primaryAttempts == 3)
        #expect(fallbackAttempts == 1)
        #expect(delays == [2, 4])
    }

    @Test("authentication failures skip retries and go straight to fallback")
    func authenticationSkipsRetries() throws {
        var primaryAttempts = 0
        var fallbackAttempts = 0
        var delays: [TimeInterval] = []

        try GitPushRecovery.perform(
            policy: policy(),
            classification: { _ in .authentication },
            primary: {
                primaryAttempts += 1
                throw TestError(message: "Authentication failed")
            },
            fallback: { fallbackAttempts += 1 },
            sleep: { delays.append($0) }
        )

        #expect(primaryAttempts == 1)
        #expect(fallbackAttempts == 1)
        #expect(delays.isEmpty)
    }

    @Test("permanent failures are surfaced without fallback")
    func permanentFailuresDoNotFallBack() {
        var fallbackAttempts = 0

        #expect(throws: TestError.self) {
            try GitPushRecovery.perform(
                policy: policy(),
                classification: { _ in .permanent },
                primary: { throw TestError(message: "non-fast-forward") },
                fallback: { fallbackAttempts += 1 },
                sleep: { _ in }
            )
        }
        #expect(fallbackAttempts == 0)
    }

    @Test("returns the primary error when the fallback is unavailable")
    func reportsPrimaryErrorWithoutFallback() {
        do {
            try GitPushRecovery.perform(
                policy: policy(maximumAttempts: 2, initialDelay: 0),
                classification: { _ in .transient },
                primary: { throw TestError(message: "SecureTransport error: -9806") },
                sleep: { _ in }
            )
            Issue.record("Expected push recovery to fail")
        } catch let error as GitPushRecoveryError {
            #expect(error.kind == .transient)
            #expect(error.primaryMessage == "SecureTransport error: -9806")
            #expect(error.fallbackMessage == nil)
            #expect(error.localizedDescription == "SecureTransport error: -9806")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("reports both engines when the fallback fails")
    func reportsBothFailures() {
        do {
            try GitPushRecovery.perform(
                policy: policy(maximumAttempts: 1),
                classification: { _ in .authentication },
                primary: { throw TestError(message: "libgit2: authentication failed") },
                fallback: { throw TestError(message: "cli: could not read Password") },
                sleep: { _ in }
            )
            Issue.record("Expected push recovery to fail")
        } catch let error as GitPushRecoveryError {
            #expect(error.kind == .authentication)
            #expect(error.primaryMessage == "libgit2: authentication failed")
            #expect(error.fallbackMessage == "cli: could not read Password")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("a single attempt policy never sleeps")
    func singleAttemptPolicy() {
        var delays: [TimeInterval] = []

        #expect(throws: GitPushRecoveryError.self) {
            try GitPushRecovery.perform(
                policy: policy(maximumAttempts: 1),
                classification: { _ in .transient },
                primary: { throw TestError(message: "timeout") },
                sleep: { delays.append($0) }
            )
        }
        #expect(delays.isEmpty)
    }
}
