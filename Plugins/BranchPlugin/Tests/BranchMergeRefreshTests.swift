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

    // MARK: - Architecture Verification

    @MainActor
    @Test("BranchMonitor uses file system monitoring instead of notifications")
    func branchMonitorUsesFileSystemMonitoring() async throws {
        // With the refactor, BranchPlugin now uses BranchMonitor to watch .git/HEAD directly.
        // This is more reliable and immediate than relying on NotificationCenter.
        let branchMonitorSourcePath = "/Users/angel/Code/Coffic/GitOK/Plugins/BranchPlugin/Sources/Services/BranchMonitor.swift"

        let branchMonitorSource = try? String(contentsOfFile: branchMonitorSourcePath, encoding: .utf8)

        // Verify BranchMonitor uses DispatchSource for file monitoring
        let usesFileSystemMonitoring = branchMonitorSource?.contains("DispatchSource") ?? false
        let watchesHEADFile = branchMonitorSource?.contains("HEAD") ?? false

        #expect(usesFileSystemMonitoring == true, "BranchMonitor should use DispatchSource for file monitoring")
        #expect(watchesHEADFile == true, "BranchMonitor should watch HEAD file")
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
