import Foundation
import XCTest

final class GitOKGitWorkflowUITests: GitOKUITestCase {
    func testSelectingWorkingTreeFileOpensItsDiff() {
        let file = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(file.waitForExistence(timeout: 15), "The modified fixture file is missing from Changes")
        file.click()

        let diffFile = element(identifier: "gitok.git.diff.file")
        XCTAssertTrue(diffFile.waitForExistence(timeout: 15), "Selecting the changed file did not open its diff")
        XCTAssertEqual(diffFile.value as? String, "tracked.txt")
        XCTAssertTrue(element(identifier: "gitok.git.diff.panel").exists)
    }

    func testStageAndUnstageWorkingTreeChange() {
        let status = element(identifier: "gitok.worktree.status.tracked.txt")
        XCTAssertTrue(status.waitForExistence(timeout: 15), "The modified fixture file is missing from Changes")
        XCTAssertTrue(waitForLabel(status, toEqual: "Not Staged"), "The fixture change should start unstaged")

        let stage = element(identifier: "gitok.worktree.stage.tracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 5), "The Stage action is missing")
        stage.click()
        XCTAssertTrue(waitForLabel(status, toEqual: "Staged"), "Staging did not update the worktree row")

        let unstage = element(identifier: "gitok.worktree.unstage.tracked.txt")
        XCTAssertTrue(unstage.waitForExistence(timeout: 5), "The Unstage action is missing")
        unstage.click()
        XCTAssertTrue(waitForLabel(status, toEqual: "Not Staged"), "Unstaging did not restore the worktree state")
    }

    func testUntrackedFileCanBeStagedAndCommitted() throws {
        let status = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(status.waitForExistence(timeout: 15), "The untracked fixture file is missing from Changes")
        XCTAssertTrue(waitForLabel(status, toEqual: "Untracked"), "The fixture file should start untracked")

        let stage = element(identifier: "gitok.worktree.stage.untracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 5), "The untracked file has no Stage action")
        stage.click()
        XCTAssertTrue(
            waitForLabel(status, toEqual: "Staged", timeout: 10),
            "Staging the new file did not update its status"
        )
        XCTAssertTrue(try gitOutput(["diff", "--cached", "--name-only"]).contains("untracked.txt"))

        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 10))
        let marker = "ui-untracked-\(UUID().uuidString)"
        replaceText(in: subject, with: "Add \(marker)")
        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(waitUntilEnabled(commit), "A staged new file should be committable")
        commit.click()

        let deadline = Date().addingTimeInterval(15)
        var latestSubject = ""
        while Date() < deadline {
            latestSubject = try gitOutput(["log", "-1", "--format=%s"])
            if latestSubject.contains(marker) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(latestSubject.contains(marker), "The staged new file was not committed")
        XCTAssertEqual(try gitOutput(["ls-tree", "--name-only", "HEAD", "--", "untracked.txt"]), "untracked.txt")
    }

    func testBatchStageAndUnstageSelectedFiles() throws {
        let trackedSelection = element(identifier: "gitok.worktree.select.tracked.txt")
        let untrackedSelection = element(identifier: "gitok.worktree.select.untracked.txt")
        XCTAssertTrue(trackedSelection.waitForExistence(timeout: 15))
        XCTAssertTrue(untrackedSelection.waitForExistence(timeout: 5))
        trackedSelection.click()
        untrackedSelection.click()

        let stage = element(identifier: "gitok.worktree.batch.stage")
        XCTAssertTrue(waitUntilEnabled(stage), "Selecting changed files should enable batch Stage")
        stage.click()
        let trackedStatus = element(identifier: "gitok.worktree.status.tracked.txt")
        let untrackedStatus = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(waitForLabel(trackedStatus, toEqual: "Staged"))
        XCTAssertTrue(waitForLabel(untrackedStatus, toEqual: "Staged"))
        XCTAssertEqual(
            try gitOutput(["diff", "--cached", "--name-only"]).split(separator: "\n").sorted(),
            ["tracked.txt", "untracked.txt"]
        )
        XCTAssertEqual(
            try gitOutput(["show", ":untracked.txt"]),
            try String(contentsOf: repositoryURL.appendingPathComponent("untracked.txt"), encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "Batch Stage should capture the current contents of the new file"
        )

        element(identifier: "gitok.worktree.select.tracked.txt").click()
        element(identifier: "gitok.worktree.select.untracked.txt").click()
        let unstage = element(identifier: "gitok.worktree.batch.unstage")
        XCTAssertTrue(waitUntilEnabled(unstage), "Selecting staged files should enable batch Unstage")
        unstage.click()
        XCTAssertTrue(waitForLabel(trackedStatus, toEqual: "Not Staged"))
        XCTAssertTrue(
            waitForLabel(untrackedStatus, toEqual: "Untracked"),
            "Untracked file status did not return after batch unstage"
        )
        XCTAssertEqual(try gitOutput(["diff", "--cached", "--name-only"]), "")
    }

    func testDiscardAllChangesRequiresConfirmation() throws {
        let discardAll = element(identifier: "gitok.worktree.discard-all")
        XCTAssertTrue(discardAll.waitForExistence(timeout: 15), "Discard All is missing from Changes")
        discardAll.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discard All did not ask for confirmation")
        let confirm = alert.buttons["Discard All Changes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The confirmation has no destructive action")
        confirm.click()

        let deadline = Date().addingTimeInterval(15)
        var status = ""
        while Date() < deadline {
            status = try gitOutput(["status", "--porcelain"])
            if status.isEmpty { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(status.isEmpty, "Discard All left repository changes behind: \(status)")
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "initial content\n"
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testCancellingDiscardAllKeepsWorkingTreeChanges() throws {
        let discardAll = element(identifier: "gitok.worktree.discard-all")
        XCTAssertTrue(discardAll.waitForExistence(timeout: 15), "Discard All is missing from Changes")
        discardAll.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discard All did not ask for confirmation")
        let cancel = alert.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Discard All confirmation has no Cancel action")
        cancel.click()

        XCTAssertFalse(alert.waitForExistence(timeout: 1), "Cancelling should close the confirmation")
        XCTAssertEqual(
            try gitOutput(["status", "--porcelain"]).split(separator: "\n").count,
            2,
            "Cancelling Discard All must leave both fixture changes intact"
        )
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "modified by the UI test\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testDiscardingOneFileLeavesOtherChangesUntouched() throws {
        let discardTracked = element(identifier: "gitok.worktree.discard.tracked.txt")
        XCTAssertTrue(discardTracked.waitForExistence(timeout: 15), "The modified fixture file has no Discard action")
        discardTracked.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discarding one file did not ask for confirmation")
        let confirm = alert.buttons["Discard"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The confirmation has no single-file Discard action")
        confirm.click()

        let deadline = Date().addingTimeInterval(15)
        var status = ""
        while Date() < deadline {
            status = try gitOutput(["status", "--porcelain"])
            if status == "?? untracked.txt" { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertEqual(status, "?? untracked.txt", "Discarding the tracked file should preserve the unrelated untracked file")
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "initial content\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testCommitButtonCreatesCommitFromStagedChange() throws {
        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(commit.waitForExistence(timeout: 10), "The Commit action is missing")
        XCTAssertTrue(commit.isEnabled, "The Commit action should be available for the active project")

        let stage = element(identifier: "gitok.worktree.stage.tracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 15), "The fixture change is missing from Changes")
        stage.click()
        XCTAssertTrue(
            waitForLabel(element(identifier: "gitok.worktree.status.tracked.txt"), toEqual: "Staged"),
            "The fixture change did not stage"
        )

        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 10), "The commit subject field is missing")
        let marker = "ui-\(UUID().uuidString)"
        replaceText(in: subject, with: "Commit \(marker)")

        XCTAssertTrue(commit.waitForExistence(timeout: 5), "The Commit action is missing")
        XCTAssertTrue(commit.isEnabled, "Commit should be enabled after entering a message")
        commit.click()

        let deadline = Date().addingTimeInterval(15)
        var latestSubject = ""
        while Date() < deadline {
            latestSubject = try gitOutput(["log", "-1", "--format=%s"])
            if latestSubject.contains(marker) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(latestSubject.contains(marker), "Commit did not write the submitted message to Git")
    }

    func testBranchPickerCreatesAndChecksOutBranch() throws {
        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 15), "The branch picker is missing")
        XCTAssertTrue(waitUntilEnabled(switcher), "The current branch did not finish loading")
        switcher.click()

        let createToggle = element(identifier: "gitok.git.branch.create.toggle")
        XCTAssertTrue(createToggle.waitForExistence(timeout: 5), "The new-branch control is missing")
        XCTAssertTrue(waitUntilEnabled(createToggle), "The branch list did not finish loading")
        createToggle.click()

        let name = "ui-\(UUID().uuidString.prefix(8))"
        let nameField = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "The branch-name field is missing")
        replaceText(in: nameField, with: name)
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "value == %@", name), on: nameField, timeout: 5),
            "The branch-name field did not retain the entered name"
        )

        let create = element(identifier: "gitok.git.branch.create")
        XCTAssertTrue(waitUntilEnabled(create), "A non-empty branch name should enable Create")
        create.click()

        let currentBranch = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label CONTAINS %@", name), on: currentBranch, timeout: 15),
            "Creating the branch did not update the toolbar"
        )
        XCTAssertEqual(try gitOutput(["branch", "--show-current"]), name)

        switcher.click()
        let mainBranch = element(identifier: "gitok.git.branch.option.main")
        XCTAssertTrue(mainBranch.waitForExistence(timeout: 5), "The existing main branch is missing from the picker")
        mainBranch.click()
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label CONTAINS %@", "main"), on: currentBranch, timeout: 15),
            "Selecting an existing branch did not update the toolbar"
        )
        XCTAssertEqual(try gitOutput(["branch", "--show-current"]), "main")
    }

    func testBranchPickerSearchFiltersLocalBranches() throws {
        let branchName = "ui-search-\(UUID().uuidString.prefix(8))"
        _ = try gitOutput(["branch", branchName])

        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 15), "The branch picker is missing")
        XCTAssertTrue(waitUntilEnabled(switcher), "The branch list did not finish loading")
        switcher.click()

        let matchingBranch = element(identifier: "gitok.git.branch.option.\(branchName)")
        XCTAssertTrue(matchingBranch.waitForExistence(timeout: 10), "The new local branch was not listed")
        let mainBranch = element(identifier: "gitok.git.branch.option.main")
        XCTAssertTrue(mainBranch.exists, "The unfiltered list should initially include main")

        let search = element(identifier: "gitok.git.branch.search")
        XCTAssertTrue(search.waitForExistence(timeout: 5), "The branch search field is missing")
        replaceText(in: search, with: String(branchName.suffix(8)))

        XCTAssertTrue(matchingBranch.waitForExistence(timeout: 5), "Searching should retain the matching branch")
        XCTAssertFalse(mainBranch.exists, "Searching should filter out branches that do not match")
    }

}
import Foundation
import XCTest
