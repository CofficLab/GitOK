@testable import ConflictResolverPlugin
import Foundation
import GitCoreKit
import GitOKCoreKit
import SwiftUI
import Testing

@Suite("ConflictResolverPlugin")
struct ConflictResolverPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(ConflictResolverPlugin.metadata.id == "ConflictResolverPlugin")
        #expect(ConflictResolverPlugin.metadata.iconName == "exclamationmark.triangle")
        #expect(ConflictResolverPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(ConflictResolverPlugin.metadata.displayName.isEmpty == false)
        #expect(ConflictResolverPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), isGitRepository: true)

        #expect(!ConflictResolverPlugin.statusBarTrailingItems(context: context).isEmpty)
    }

    @MainActor
    @Test("plugin contributes root conflict overlay wrapper")
    func rootView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), isGitRepository: true)
        let root = AnyView(Text("Root"))

        #expect(ConflictResolverPlugin.rootOverlay(context: context, content: root) != nil)
    }

    @Test("state builder prioritizes unresolved files")
    func stateBuilder() {
        let files = ConflictResolverStateBuilder.mergeFiles(
            unresolvedPaths: ["a.txt"],
            statusEntries: [
                GitStatusEntry(path: "a.txt", indexStatus: " ", workTreeStatus: "M"),
                GitStatusEntry(path: "b.txt", indexStatus: "M", workTreeStatus: " ")
            ]
        )

        #expect(files == [
            GitMergeFile(path: "a.txt", state: .unresolved),
            GitMergeFile(path: "b.txt", state: .staged)
        ])
    }

    @Test("conflict state blocks continue until every file is staged")
    func conflictResolutionState() {
        let unresolved = ConflictResolutionState(
            isMerging: true,
            mergeFiles: [
                GitMergeFile(path: "conflict.swift", state: .unresolved),
                GitMergeFile(path: "resolved.swift", state: .staged),
            ]
        )

        #expect(unresolved.hasStagedResolutions)
        #expect(unresolved.hasUnresolvedFiles)
        #expect(unresolved.canContinueMerge == false)
        #expect(unresolved.continueHint == "Resolve conflicts before continue")

        let fullyStaged = ConflictResolutionState(
            isMerging: true,
            mergeFiles: [
                GitMergeFile(path: "a.swift", state: .staged),
                GitMergeFile(path: "b.swift", state: .staged),
            ]
        )

        #expect(fullyStaged.hasPendingUnstagedResolutions == false)
        #expect(fullyStaged.canContinueMerge)
        #expect(fullyStaged.statusSubtitle == "所有合并文件都已暂存，可以继续完成合并。")
    }
}
