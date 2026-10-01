import Foundation
import XCTest

class GitOKCloneFailureFixtureTestCase: GitOKUITestCase {
    let kuzeeRemoteURL = "https://github.com/CofficLab/Kuzee.git"
    var shouldSeedExternalClone: Bool { false }

    override var expectsReadyGitWorkbench: Bool { false }

    override var fixtureProjectTitle: String { "Kuzee" }

    override func additionalProjectFixtures() throws -> [UITestProject] {
        let lumiURL = fixtureRootURL.appendingPathComponent("Lumi", isDirectory: true)
        try createCleanRepository(at: lumiURL)
        return [
            UITestProject(
                id: UUID(),
                url: lumiURL,
                title: "Lumi",
                isPinned: false
            ),
        ]
    }

    override func seedAdditionalUIState() throws {
        if shouldSeedExternalClone {
            _ = try gitOutput(["remote", "add", "origin", kuzeeRemoteURL], in: repositoryURL)
        }

        let cloneDirectory = fixtureRootURL
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.clone-repository", isDirectory: true)
        try FileManager.default.createDirectory(at: cloneDirectory, withIntermediateDirectories: true)

        let now = Date()
        let task = UITestCloneTask(
            id: UUID(),
            remoteURL: kuzeeRemoteURL,
            destination: repositoryURL,
            repositoryName: "Kuzee",
            status: "failed",
            phase: "checkingOut",
            fractionCompleted: 0.92,
            detail: "Clone failed",
            errorMessage: "remote authentication required but no callback set",
            createdAt: now,
            updatedAt: now,
            startedAt: now,
            finishedAt: now
        )
        let store = UITestCloneTaskStore(tasks: [task])
        try JSONEncoder().encode(store).write(
            to: cloneDirectory.appendingPathComponent("clone-tasks.json"),
            options: .atomic
        )
    }
}

final class GitOKCloneFailureIsolationUITests: GitOKCloneFailureFixtureTestCase {
    func testFailedCloneHidesGitWorkbenchAndRail() {
        XCTAssertTrue(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 15),
            "The seeded Kuzee clone failure was not displayed"
        )
        XCTAssertTrue(
            element(identifier: "gitok.clone.failure").waitForExistence(timeout: 5),
            "The clone failure page was not mounted as the unavailable workspace"
        )

        let railVisible = element(identifier: "gitok.workspace.rail").waitForExistence(timeout: 2)
        let branchSwitcherVisible = element(identifier: "gitok.git.branch.switcher").waitForExistence(timeout: 2)
        let commitFormVisible = element(identifier: "gitok.commit.subject").waitForExistence(timeout: 2)

        XCTAssertFalse(
            railVisible,
            "The RailView is visible even though the current project clone failed"
        )
        XCTAssertFalse(
            branchSwitcherVisible,
            "The Git branch UI is visible even though the current project clone failed"
        )
        XCTAssertFalse(
            commitFormVisible,
            "The commit form is visible even though the current project clone failed"
        )
    }

    func testFailedCloneDetailsDoNotLeakAfterSwitchingProjects() {
        XCTAssertTrue(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 15),
            "The seeded Kuzee clone failure was not displayed"
        )

        let lumi = app.buttons.matching(NSPredicate(format: "label == %@", "Lumi")).firstMatch
        XCTAssertTrue(lumi.waitForExistence(timeout: 10), "The Lumi project row is missing")
        lumi.click()

        XCTAssertFalse(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 2),
            "Kuzee clone details leaked into the Lumi project"
        )
    }
}

final class GitOKExternalCloneReconciliationUITests: GitOKCloneFailureFixtureTestCase {
    override var shouldSeedExternalClone: Bool { true }

    func testExternalCloneShouldClearStaleFailedCloneTask() throws {
        XCTAssertEqual(
            try gitOutput(["rev-parse", "--is-inside-work-tree"], in: repositoryURL),
            "true",
            "The fixture destination should represent a repository cloned outside GitOK"
        )

        XCTAssertFalse(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 2),
            "GitOK still shows the stale clone failure after the destination became a valid repository"
        )
    }
}
import Foundation
import XCTest
