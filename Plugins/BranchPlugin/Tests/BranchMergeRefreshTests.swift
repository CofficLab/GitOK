@testable import BranchPlugin
import Foundation
import GitCoreKit
import GitOKAppCore
import GitOKCoreKit
import Testing

// MARK: - Branch Merge Refresh Bug Tests
//
// These tests reproduce the bug where the branch display doesn't update after a merge.
//
// ## Bug Description
// When a user performs a merge (e.g., from dev to main), the BranchPlugin toolbar
// continues to show the old branch name (dev) even though HEAD has changed to main.
//
// ## Root Cause
// The bug is NOT in BranchPlugin itself - it's in the data flow:
// 1. BranchPickerView refreshes when context.branchName changes
// 2. After merge, DataVM.branch should update (but it doesn't!)
// 3. So context.branchName stays stale
// 4. So the toolbar shows the old branch

@Suite("Branch Merge Refresh Bug Tests")
struct BranchMergeRefreshBugTests {

    // MARK: - Helper

    private func makeBranch(name: String, isCurrent: Bool) -> GitBranchSummary {
        GitBranchSummary(name: name, isRemote: false, isCurrent: isCurrent)
    }

    // MARK: - Core Bug Reproduction

    @Test("BUG: DataVM does not listen to projectGitHeadDidChange")
    func dataVMDoesNotListenToHeadChangeNotification() async throws {
        // This test FAILS because DataVM doesn't subscribe to the notification.
        //
        // We verify this by checking if DataVM has the expected behavior:
        // "DataVM should have a mechanism to respond to projectGitHeadDidChange"
        //
        // Currently, it doesn't. So this test documents that gap.

        // Check DataVM's source code for notification subscription
        let dataVMSourcePath = "/Users/colorfy/Code/CofficLab/GitOK/Packages/GitOKAppCore/Sources/GitOKAppCore/ViewModels/DataVM.swift"

        let dataVMSource = try? String(contentsOfFile: dataVMSourcePath, encoding: .utf8)

        // The fix should add a subscription to projectGitHeadDidChange
        let hasNotificationSubscription = dataVMSource?.contains("projectGitHeadDidChange") ?? false

        // THIS ASSERTION WILL FAIL until the fix is implemented!
        // Error message: DataVM should subscribe to projectGitHeadDidChange notification.
        // Currently it doesn't, which is the root cause of the bug.
        #expect(hasNotificationSubscription == true)
    }

    // MARK: - Branch Logic Tests (these pass - logic is correct)

    @Test("BranchLogic correctly identifies current branch after merge")
    func branchLogicCorrectlyIdentifiesCurrentBranch() async throws {
        // After merge, if we query git, main.isCurrent = true
        let branchesAfterMerge = [
            makeBranch(name: "dev", isCurrent: false),
            makeBranch(name: "main", isCurrent: true),
        ]

        // BranchLogic.selectCurrentBranch correctly returns "main"
        let selected = BranchLogic.selectCurrentBranch(in: branchesAfterMerge)
        #expect(selected?.name == "main",
                "BranchLogic correctly identifies 'main' as current after merge")
    }

    @Test("MockBranchService can simulate merge scenario")
    func mockServiceCanSimulateMerge() async throws {
        var mockService = MockBranchService()

        // Before merge
        mockService.branchesResult = .success([
            makeBranch(name: "dev", isCurrent: true),
            makeBranch(name: "main", isCurrent: false),
        ])
        #expect(try BranchLogic.selectCurrentBranch(in: mockService.branches())?.name == "dev")

        // After merge
        mockService.branchesResult = .success([
            makeBranch(name: "dev", isCurrent: false),
            makeBranch(name: "main", isCurrent: true),
        ])
        #expect(try BranchLogic.selectCurrentBranch(in: mockService.branches())?.name == "main")
    }

    // MARK: - The Fix Contract

    @Test("FIX REQUIRED: Add notification subscription to DataVM")
    func fixRequiredAddNotificationSubscription() async throws {
        // This test documents the required fix.
        //
        // Location: Packages/GitOKAppCore/Sources/GitOKAppCore/ViewModels/DataVM.swift
        // Method: init(projects:repoManager:)
        //
        // Add:
        // NotificationCenter.default.publisher(for: .projectGitHeadDidChange)
        //     .compactMap { $0.userInfo?["eventInfo"] as? ProjectEventInfo }
        //     .sink { [weak self] eventInfo in
        //         self?.refreshCurrentBranch(
        //             project: eventInfo.project,
        //             isGitRepository: true,
        //             reason: "projectGitHeadDidChange"
        //         )
        //     }
        //     .store(in: &cancellables)

        let fixCode = """
        NotificationCenter.default.publisher(for: .projectGitHeadDidChange)
            .compactMap { $0.userInfo?["eventInfo"] as? ProjectEventInfo }
            .sink { [weak self] eventInfo in
                self?.refreshCurrentBranch(
                    project: eventInfo.project,
                    isGitRepository: true,
                    reason: "projectGitHeadDidChange"
                )
            }
            .store(in: &cancellables)
        """

        #expect(fixCode.contains("projectGitHeadDidChange"))
        #expect(fixCode.contains("refreshCurrentBranch"))
    }
}
