@testable import PluginGitDetail
import AppKit
import Foundation
import SwiftUI
import Testing

@Suite("PluginGitDetail")
struct GitDetailPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitDetailPlugin.metadata.id == "GitDetailPlugin")
        #expect(GitDetailPlugin.metadata.iconName == "puzzlepiece.extension")
        #expect(GitDetailPlugin.metadata.order == 0)
        #expect(GitDetailPlugin.metadata.allowUserToggle == false)
        #expect(GitDetailPlugin.metadata.defaultEnabled == true)
        #expect(GitDetailPlugin.metadata.tableName == "GitDetail")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitDetailPlugin.metadata.displayName.isEmpty == false)
    }

    @Test("git detail alert rules normalize failure presentation")
    func gitDetailAlertRules() {
        struct AlertError: LocalizedError {
            var errorDescription: String? { "file operation failed" }
        }

        #expect(GitDetailAlertRules.errorMessage(from: AlertError()) == "file operation failed")
        var alertMessages: [String] = []
        GitDetailAlertRules.performError(AlertError()) {
            alertMessages.append($0)
        }
        GitDetailAlertRules.performMessage("validation failed") {
            alertMessages.append($0)
        }
        var infoMessages: [String] = []
        GitDetailAlertRules.performInfo("files staged") {
            infoMessages.append($0)
        }
        #expect(alertMessages == ["file operation failed", "validation failed"])
        #expect(infoMessages == ["files staged"])
    }

    @Test("diff block splits lines into stable diff entries")
    func diffBlockSplitsLines() {
        let diffs = DiffBlock.fromBlock("+one\n-two").getDiffs()

        #expect(diffs.map(\.message) == ["+one", "-two"])
        #expect(diffs[0].id.isEmpty == false)
        #expect(diffs[0].id != diffs[1].id)
    }

    @Test("git detail error maps known contexts")
    func gitDetailErrorMapsContexts() {
        let error = NSError(domain: "test", code: 1)

        #expect(GitDetailError.from(error, context: "getFileDiff").errorDescription == "获取文件差异失败")
        #expect(GitDetailError.invalidProject.errorDescription == "项目无效")
    }

    @Test("image diff mode metadata stays stable")
    func imageDiffModeMetadata() {
        #expect(GitDetailImageDiffMode.allCases.map(\.rawValue) == ["twoUp", "swipe", "onion", "difference"])
        #expect(GitDetailImageDiffMode.swipe.usesBlendAmount)
        #expect(GitDetailImageDiffMode.onion.usesBlendAmount)
        #expect(GitDetailImageDiffMode.twoUp.usesBlendAmount == false)
        #expect(GitDetailImageDiffMode.difference.usesBlendAmount == false)
        #expect(GitDetailImageDiffMode.onion.valueLabel(for: 0.625) == "63%")
        #expect(GitDetailImageDiffMode.difference.accessibilityLabel.isEmpty == false)
    }

    @Test("diff display rules map file states")
    func diffDisplayRules() throws {
        #expect(GitDetailDiffDisplayRules.hasBeforeText(changeType: "A") == false)
        #expect(GitDetailDiffDisplayRules.hasBeforeText(changeType: "?") == false)
        #expect(GitDetailDiffDisplayRules.hasBeforeText(changeType: "M"))
        #expect(GitDetailDiffDisplayRules.hasAfterText(changeType: "D") == false)
        #expect(GitDetailDiffDisplayRules.hasAfterText(changeType: "M"))
        #expect(GitDetailDiffDisplayRules.changeTypeLabel("M") == "Modified")
        #expect(GitDetailDiffDisplayRules.changeTypeLabel("custom") == "custom")
        #expect(GitDetailDiffDisplayRules.emptyDiffExplanation(changeType: "A", issueMessage: nil).isEmpty == false)
        #expect(GitDetailDiffDisplayRules.emptyDiffExplanation(changeType: "M", issueMessage: "failed").isEmpty == false)
        #expect(GitDetailDiffDisplayRules.fileIcon(isImage: true, isBinary: true) == "photo")
        #expect(GitDetailDiffDisplayRules.fileIcon(isImage: false, isBinary: true) == "doc.badge.gearshape")
        #expect(GitDetailDiffDisplayRules.fileIcon(isImage: false, isBinary: false) == "doc.text")
        #expect(GitDetailDiffDisplayRules.fileDetailPresentationState(
            isImage: true,
            isBinary: true,
            changeType: "A",
            diffText: ""
        ) == .init(
            fileIcon: "photo",
            diffContentMode: .empty,
            imageDisplayMode: .new,
            canShowBeforeText: false,
            canShowAfterText: true
        ))
        #expect(GitDetailDiffDisplayRules.fileDetailPresentationState(
            isImage: false,
            isBinary: false,
            changeType: "M",
            diffText: "-old\n+new"
        ) == .init(
            fileIcon: "doc.text",
            diffContentMode: .render,
            imageDisplayMode: .comparison,
            canShowBeforeText: true,
            canShowAfterText: true
        ))
        #expect(GitDetailDiffDisplayRules.defaultFileIcon == "doc.text")
        #expect(GitDetailDiffDisplayRules.manualRefreshReason == "Manual Refresh")
        #expect(GitDetailDiffDisplayRules.fileChangeRefreshReason == "File Change")
        #expect(GitDetailDiffDisplayRules.commitChangeRefreshReason == "Commit Change")
        #expect(GitDetailDiffDisplayRules.appearRefreshReason == "Appear")
        #expect(GitDetailDiffDisplayRules.imageDisplayMode(changeType: "A") == .new)
        #expect(GitDetailDiffDisplayRules.imageDisplayMode(changeType: "?") == .new)
        #expect(GitDetailDiffDisplayRules.imageDisplayMode(changeType: "D") == .deleted)
        #expect(GitDetailDiffDisplayRules.imageDisplayMode(changeType: "M") == .comparison)
        #expect(GitDetailDiffDisplayRules.defaultImageBlendAmount == 0.5)
        #expect(GitDetailDiffDisplayRules.imagePreviewTitle(for: .new).isEmpty == false)
        #expect(GitDetailDiffDisplayRules.imagePreviewTitle(for: .deleted).isEmpty == false)
        #expect(GitDetailDiffDisplayRules.imagePreviewTitle(for: .comparison).isEmpty == false)
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: true,
            hasSelectedCommit: true,
            existingPatch: "patch"
        ) == .noneForBinary)
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: false,
            hasSelectedCommit: true,
            existingPatch: "patch"
        ) == .commit)
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: false,
            hasSelectedCommit: false,
            existingPatch: "patch"
        ) == .existingPatch("patch"))
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: false,
            hasSelectedCommit: false,
            existingPatch: ""
        ) == .worktree)
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: false,
            selectedCommit: "abc" as String?,
            existingPatch: ""
        ) == .commit)
        #expect(GitDetailDiffDisplayRules.diffSource(
            isBinary: false,
            selectedCommit: nil as String?,
            existingPatch: "patch"
        ) == .existingPatch("patch"))
        #expect(GitDetailDiffDisplayRules.diffTextStateForBinary() == .init(text: "", issueMessage: nil))
        #expect(GitDetailDiffDisplayRules.diffTextStateForLoadedText("-old\n+new") == .init(
            text: "-old\n+new",
            issueMessage: nil
        ))
        #expect(GitDetailDiffDisplayRules.diffTextStateForFailure(errorDescription: "failed") == .init(
            text: "",
            issueMessage: "failed"
        ))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .noneForBinary,
            loadCommitDiff: { "commit" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForBinary(), errorDescription: nil))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .existingPatch("patch"),
            loadCommitDiff: { "commit" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForLoadedText("patch"), errorDescription: nil))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .commit,
            loadCommitDiff: { "commit" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForLoadedText("commit"), errorDescription: nil))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .commit,
            selectedCommitHash: "abc",
            loadCommitDiff: { "commit:\($0)" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForLoadedText("commit:abc"), errorDescription: nil))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .commit,
            selectedCommit: (hash: "abc", index: 0),
            commitHash: \.hash,
            loadCommitDiff: { "commit:\($0)" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForLoadedText("commit:abc"), errorDescription: nil))
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .commit,
            selectedCommitHash: nil,
            loadCommitDiff: { "commit:\($0)" },
            loadWorktreeDiff: { "worktree" }
        ).errorDescription?.isEmpty == false)
        #expect(GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .worktree,
            loadCommitDiff: { "commit" },
            loadWorktreeDiff: { "worktree" }
        ) == .init(state: GitDetailDiffDisplayRules.diffTextStateForLoadedText("worktree"), errorDescription: nil))
        let diffFailure = GitDetailDiffDisplayRules.diffTextLoadResult(
            source: .commit,
            loadCommitDiff: {
                throw NSError(
                    domain: "diff",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "failed"]
                )
            },
            loadWorktreeDiff: { "worktree" }
        )
        #expect(diffFailure.errorDescription == "failed")
        #expect(diffFailure.state == GitDetailDiffDisplayRules.diffTextStateForFailure(errorDescription: "failed"))
        #expect(GitDetailDiffDisplayRules.fileContentSource(selectedCommitHash: "abc") == .commit(hash: "abc"))
        #expect(GitDetailDiffDisplayRules.fileContentSource(selectedCommitHash: nil) == .worktree)
        #expect(GitDetailDiffDisplayRules.fileContentSource(
            selectedCommit: (hash: "abc", index: 0),
            commitHash: \.hash
        ) == .commit(hash: "abc"))
        #expect(GitDetailDiffDisplayRules.fileContentSource(
            selectedCommit: nil as (hash: String, index: Int)?,
            commitHash: \.hash
        ) == .worktree)
        #expect(try GitDetailDiffDisplayRules.textContent(
            version: .after,
            source: .commit(hash: "abc"),
            loadCommitContent: { hash in
                (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: {
                (before: "worktree-before", after: "worktree-after")
            }
        ) == "after-abc")
        #expect(try GitDetailDiffDisplayRules.textContent(
            version: .before,
            source: .worktree,
            loadCommitContent: { hash in
                (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: {
                (before: "worktree-before", after: "worktree-after")
            }
        ) == "worktree-before")
        #expect(try GitDetailDiffDisplayRules.textContent(
            version: .after,
            selectedCommit: (hash: "abc", index: 0),
            commitHash: \.hash,
            loadCommitContent: { hash in
                (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: {
                (before: "worktree-before", after: "worktree-after")
            }
        ) == "after-abc")
        #expect(try GitDetailDiffDisplayRules.textContent(
            version: .before,
            selectedCommit: Optional<(hash: String, index: Int)>.none,
            commitHash: \.hash,
            loadCommitContent: { hash in
                (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: {
                (before: "worktree-before", after: "worktree-after")
            }
        ) == "worktree-before")
        var projectTextLoadEvents: [String] = []
        #expect(try GitDetailDiffDisplayRules.projectTextContent(
            version: .after,
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            selectedCommit: Optional("abc"),
            commitHash: { $0 },
            loadCommitContent: { project, hash in
                projectTextLoadEvents.append("commit:\(project):\(hash)")
                return (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: { project in
                projectTextLoadEvents.append("worktree:\(project)")
                return (before: "worktree-before", after: "worktree-after")
            }
        ) == "after-abc")
        #expect(try GitDetailDiffDisplayRules.projectTextContent(
            version: .before,
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            loadCommitContent: { project, hash in
                projectTextLoadEvents.append("commit:\(project):\(hash)")
                return (before: "before-\(hash)", after: "after-\(hash)")
            },
            loadWorktreeContent: { project in
                projectTextLoadEvents.append("worktree:\(project)")
                return (before: "worktree-before", after: "worktree-after")
            }
        ) == "worktree-before")
        #expect(projectTextLoadEvents == [
            "commit:repo:abc",
            "worktree:repo",
        ])
        #expect(throws: GitDetailError.self) {
            try GitDetailDiffDisplayRules.projectTextContent(
                version: .after,
                project: Optional<String>.none,
                missingError: GitDetailError.invalidProject,
                selectedCommit: Optional("abc"),
                commitHash: { $0 },
                loadCommitContent: { project, hash in
                    projectTextLoadEvents.append("commit:\(project):\(hash)")
                    return (before: nil, after: nil)
                },
                loadWorktreeContent: { project in
                    projectTextLoadEvents.append("worktree:\(project)")
                    return (before: nil, after: nil)
                }
            )
        }
        #expect(try GitDetailDiffDisplayRules.imageData(
            source: .commit(hash: "abc"),
            loadCommitData: { hash in Data("commit-\(hash)".utf8) },
            loadWorktreeData: { Data("worktree".utf8) }
        ) == Data("commit-abc".utf8))
        #expect(try GitDetailDiffDisplayRules.imageData(
            source: .worktree,
            loadCommitData: { hash in Data("commit-\(hash)".utf8) },
            loadWorktreeData: { Data("worktree".utf8) }
        ) == Data("worktree".utf8))
        #expect(try GitDetailDiffDisplayRules.imageData(
            source: GitDetailDiffDisplayRules.PreviousFileContentSource.commit(hash: "parent"),
            loadCommitData: { hash in Data("previous-\(hash)".utf8) }
        ) == Data("previous-parent".utf8))
        #expect(try GitDetailDiffDisplayRules.imageData(
            source: GitDetailDiffDisplayRules.PreviousFileContentSource.unavailable,
            loadCommitData: { hash in Data("previous-\(hash)".utf8) }
        ) == nil)
        #expect(GitDetailDiffDisplayRules.optionalImageData(
            source: .commit(hash: "abc"),
            loadCommitData: { hash in Data("commit-\(hash)".utf8) },
            loadWorktreeData: { Data("worktree".utf8) }
        ) == Data("commit-abc".utf8))
        #expect(GitDetailDiffDisplayRules.optionalImageData(
            source: .worktree,
            loadCommitData: { hash in Data("commit-\(hash)".utf8) },
            loadWorktreeData: { throw NSError(domain: "GitOKTests", code: 1) }
        ) == nil)
        #expect(GitDetailDiffDisplayRules.optionalImageData(
            source: GitDetailDiffDisplayRules.PreviousFileContentSource.commit(hash: "parent"),
            loadCommitData: { hash in Data("previous-\(hash)".utf8) }
        ) == Data("previous-parent".utf8))
        #expect(GitDetailDiffDisplayRules.optionalImageData(
            source: GitDetailDiffDisplayRules.PreviousFileContentSource.commit(hash: "parent"),
            loadCommitData: { _ in throw NSError(domain: "GitOKTests", code: 2) }
        ) == nil)
        #expect(GitDetailDiffDisplayRules.optionalCurrentImageData(
            selectedCommit: (hash: "abc", index: 0),
            commitHash: \.hash,
            loadCommitData: { hash in Data("current-\(hash)".utf8) },
            loadWorktreeData: { Data("worktree".utf8) }
        ) == Data("current-abc".utf8))
        #expect(GitDetailDiffDisplayRules.optionalCurrentImageData(
            selectedCommit: Optional<(hash: String, index: Int)>.none,
            commitHash: \.hash,
            loadCommitData: { hash in Data("current-\(hash)".utf8) },
            loadWorktreeData: { Data("worktree".utf8) }
        ) == Data("worktree".utf8))
        struct CommitSummaryFixture {
            let id: String
            let parents: [String]
        }
        #expect(GitDetailDiffDisplayRules.optionalPreviousImageData(
            selectedCommit: (hash: "child", index: 0),
            commitHash: \.hash,
            loadCommits: {
                [
                    CommitSummaryFixture(id: "child", parents: ["parent"]),
                    CommitSummaryFixture(id: "parent", parents: []),
                ]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { "ignored" },
            loadCommitData: { hash in Data("previous-\(hash)".utf8) }
        ) == Data("previous-parent".utf8))
        #expect(GitDetailDiffDisplayRules.optionalPreviousImageData(
            selectedCommit: Optional<(hash: String, index: Int)>.none,
            commitHash: \.hash,
            loadCommits: { [] as [CommitSummaryFixture] },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { "head" },
            loadCommitData: { hash in Data("previous-\(hash)".utf8) }
        ) == Data("previous-head".utf8))
        #expect(GitDetailDiffDisplayRules.optionalRequiredProjectValue(Optional<String>.none) {
            Data($0.utf8)
        } == nil)
        #expect(GitDetailDiffDisplayRules.optionalRequiredProjectValue(Optional("repo")) {
            Data($0.utf8)
        } == Data("repo".utf8))
        #expect(try GitDetailDiffDisplayRules.requiredProjectValue(
            Optional("repo"),
            missingError: GitDetailError.invalidProject,
            perform: { "project:\($0)" }
        ) == "project:repo")
        #expect(throws: GitDetailError.self) {
            try GitDetailDiffDisplayRules.requiredProjectValue(
                Optional<String>.none,
                missingError: GitDetailError.invalidProject,
                perform: { "project:\($0)" }
            )
        }
        #expect(GitDetailDiffDisplayRules.parentHash(
            selectedCommitHash: "child",
            commits: [(hash: "child", parentHashes: ["parent"])]
        ) == "parent")
        #expect(GitDetailDiffDisplayRules.parentHash(
            selectedCommitHash: "missing",
            commits: [(hash: "child", parentHashes: ["parent"])]
        ) == nil)
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommitHash: "child",
            commits: [(hash: "child", parentHashes: ["parent"])],
            headHash: nil
        ) == .commit(hash: "parent"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommitHash: "root",
            commits: [(hash: "root", parentHashes: [])],
            headHash: nil
        ) == .unavailable)
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommitHash: nil,
            commits: [],
            headHash: "head"
        ) == .commit(hash: "head"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommitHash: nil,
            commits: [],
            headHash: nil
        ) == .unavailable)
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .commit(hash: "child"),
            commits: [(hash: "child", parentHashes: ["parent"])],
            headHash: "ignored"
        ) == .commit(hash: "parent"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .worktree,
            commits: [(hash: "child", parentHashes: ["parent"])],
            headHash: "head"
        ) == .commit(hash: "head"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .commit(hash: "child"),
            loadCommits: { [(hash: "child", parentHashes: ["parent"])] },
            loadHeadHash: { "ignored" }
        ) == .commit(hash: "parent"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .worktree,
            loadCommits: { [(hash: "child", parentHashes: ["parent"])] },
            loadHeadHash: { "head" }
        ) == .commit(hash: "head"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommit: (hash: "child", parentHashes: ["parent"]),
            commitHash: { $0.hash },
            loadCommits: { [(hash: "child", parentHashes: ["parent"])] },
            loadHeadHash: { "ignored" }
        ) == .commit(hash: "parent"))
        #expect(GitDetailDiffDisplayRules.previousFileContentSource(
            selectedCommit: Optional<(hash: String, parentHashes: [String])>.none,
            commitHash: { $0.hash },
            loadCommits: { [(hash: "child", parentHashes: ["parent"])] },
            loadHeadHash: { "head" }
        ) == .commit(hash: "head"))
        #expect(GitDetailDiffDisplayRules.safePreviousFileContentSource(
            currentSource: .commit(hash: "child"),
            loadCommits: { [(hash: "child", parentHashes: ["parent"])] },
            loadHeadHash: { "ignored" }
        ) == .commit(hash: "parent"))
        #expect(GitDetailDiffDisplayRules.safePreviousFileContentSource(
            currentSource: .commit(hash: "child"),
            loadCommits: { throw NSError(domain: "GitOKTests", code: 3) },
            loadHeadHash: { "ignored" }
        ) == .unavailable)
        #expect(GitDetailDiffDisplayRules.safePreviousFileContentSource(
            selectedCommit: Optional<(hash: String, parentHashes: [String])>.none,
            commitHash: { $0.hash },
            loadCommits: { throw NSError(domain: "GitOKTests", code: 4) },
            loadHeadHash: { "head" }
        ) == .commit(hash: "head"))
        #expect(GitDetailDiffDisplayRules.commitSummaries(
            from: [
                CommitSummaryFixture(id: "child", parents: ["parent"]),
                CommitSummaryFixture(id: "parent", parents: []),
            ],
            commitHash: \.id,
            parentHashes: \.parents
        ).map(\.hash) == ["child", "parent"])
        #expect(GitDetailDiffDisplayRules.safePreviousFileContentSource(
            selectedCommit: (hash: "child", index: 0),
            commitHash: \.hash,
            loadCommits: {
                [
                    CommitSummaryFixture(id: "child", parents: ["parent"]),
                    CommitSummaryFixture(id: "parent", parents: []),
                ]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { "ignored" }
        ) == .commit(hash: "parent"))
        var projectImageLoadEvents: [String] = []
        let commitImageData = Data("commit-image".utf8)
        let worktreeImageData = Data("worktree-image".utf8)
        let parentImageData = Data("parent-image".utf8)
        #expect(GitDetailDiffDisplayRules.worktreeFileURL(
            projectPath: "/repo",
            filePath: "Sources/App.swift"
        ).path == "/repo/Sources/App.swift")
        let loadedWorktreeData = try GitDetailDiffDisplayRules.worktreeFileData(
            projectPath: "/repo",
            filePath: "README.md",
            loadData: { url in Data(url.path.utf8) }
        )
        #expect(String(data: loadedWorktreeData, encoding: .utf8) == "/repo/README.md")
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageData(
            project: Optional<String>.none,
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadCommitData: { project, hash in
                projectImageLoadEvents.append("commit:\(project):\(hash)")
                return commitImageData
            },
            loadWorktreeData: { project in
                projectImageLoadEvents.append("worktree:\(project)")
                return worktreeImageData
            }
        ) == nil)
        #expect(projectImageLoadEvents.isEmpty)
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageData(
            project: Optional("repo"),
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadCommitData: { project, hash in
                projectImageLoadEvents.append("commit:\(project):\(hash)")
                return commitImageData
            },
            loadWorktreeData: { project in
                projectImageLoadEvents.append("worktree:\(project)")
                return worktreeImageData
            }
        ) == commitImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageData(
            project: Optional("repo"),
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            loadCommitData: { project, hash in
                projectImageLoadEvents.append("commit:\(project):\(hash)")
                return commitImageData
            },
            loadWorktreeData: { project in
                projectImageLoadEvents.append("worktree:\(project)")
                return worktreeImageData
            }
        ) == worktreeImageData)
        #expect(projectImageLoadEvents == [
            "commit:repo:child",
            "worktree:repo",
        ])
        projectImageLoadEvents.removeAll()
        #expect(GitDetailDiffDisplayRules.optionalProjectPreviousImageData(
            project: Optional("repo"),
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadCommits: { project in
                projectImageLoadEvents.append("commits:\(project)")
                return [CommitSummaryFixture(id: "child", parents: ["parent"])]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { project in
                projectImageLoadEvents.append("head:\(project)")
                return "head"
            },
            loadCommitData: { project, hash in
                projectImageLoadEvents.append("data:\(project):\(hash)")
                return parentImageData
            }
        ) == parentImageData)
        #expect(projectImageLoadEvents == [
            "commits:repo",
            "data:repo:parent",
        ])
        projectImageLoadEvents.removeAll()
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadData: { request in
                projectImageLoadEvents.append("current:\(request.project):\(request.file):\(request.source)")
                return commitImageData
            }
        ) == commitImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageDataCommand(
            project: Optional("repo"),
            file: "README.md",
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            loadData: { request in
                projectImageLoadEvents.append("current:\(request.project):\(request.file):\(request.source)")
                return worktreeImageData
            }
        ) == worktreeImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageDataCommand(
            project: Optional<String>.none,
            file: "README.md",
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadData: { request in
                projectImageLoadEvents.append("current:\(request.project):\(request.file):\(request.source)")
                return commitImageData
            }
        ) == nil)
        projectImageLoadEvents.removeAll()
        let currentImageHandlers = GitDetailDiffDisplayRules.ProjectCurrentImageDataHandlers<String, String>(
            loadCommitData: { project, file, hash in
                projectImageLoadEvents.append("handler-current-commit:\(project):\(file):\(hash)")
                return commitImageData
            },
            loadWorktreeData: { project, file in
                projectImageLoadEvents.append("handler-current-worktree:\(project):\(file)")
                return worktreeImageData
            }
        )
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            handlers: currentImageHandlers
        ) == commitImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectCurrentImageDataCommand(
            project: Optional("repo"),
            file: "README.md",
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            handlers: currentImageHandlers
        ) == worktreeImageData)
        #expect(projectImageLoadEvents == [
            "handler-current-commit:repo:Sources/App.swift:child",
            "handler-current-worktree:repo:README.md",
        ])
        projectImageLoadEvents.removeAll()
        #expect(GitDetailDiffDisplayRules.optionalProjectPreviousImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            loadCommits: { project in
                projectImageLoadEvents.append("command-commits:\(project)")
                return [CommitSummaryFixture(id: "child", parents: ["parent"])]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { project in
                projectImageLoadEvents.append("command-head:\(project)")
                return "head"
            },
            loadData: { request in
                projectImageLoadEvents.append("previous:\(request.project):\(request.file):\(request.commitHash)")
                return parentImageData
            }
        ) == parentImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectPreviousImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("missing"),
            commitHash: { $0 },
            loadCommits: { project in
                projectImageLoadEvents.append("missing-commits:\(project)")
                return [CommitSummaryFixture(id: "child", parents: ["parent"])]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { project in
                projectImageLoadEvents.append("missing-head:\(project)")
                return "head"
            },
            loadData: { request in
                projectImageLoadEvents.append("previous:\(request.project):\(request.file):\(request.commitHash)")
                return parentImageData
            }
        ) == nil)
        #expect(projectImageLoadEvents == [
            "command-commits:repo",
            "previous:repo:Sources/App.swift:parent",
            "missing-commits:repo",
        ])
        projectImageLoadEvents.removeAll()
        let previousImageHandlers = GitDetailDiffDisplayRules.ProjectPreviousImageDataHandlers<String, String, CommitSummaryFixture>(
            loadCommits: { project in
                projectImageLoadEvents.append("handler-previous-commits:\(project)")
                return [CommitSummaryFixture(id: "child", parents: ["parent"])]
            },
            loadedCommitHash: \.id,
            loadedParentHashes: \.parents,
            loadHeadHash: { project in
                projectImageLoadEvents.append("handler-previous-head:\(project)")
                return "head"
            },
            loadCommitData: { project, file, hash in
                projectImageLoadEvents.append("handler-previous-data:\(project):\(file):\(hash)")
                return parentImageData
            }
        )
        #expect(GitDetailDiffDisplayRules.optionalProjectPreviousImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("child"),
            commitHash: { $0 },
            handlers: previousImageHandlers
        ) == parentImageData)
        #expect(GitDetailDiffDisplayRules.optionalProjectPreviousImageDataCommand(
            project: Optional("repo"),
            file: "Sources/App.swift",
            selectedCommit: Optional("missing"),
            commitHash: { $0 },
            handlers: previousImageHandlers
        ) == nil)
        #expect(projectImageLoadEvents == [
            "handler-previous-commits:repo",
            "handler-previous-data:repo:Sources/App.swift:parent",
            "handler-previous-commits:repo",
        ])
        #expect(GitDetailDiffDisplayRules.shouldSkipDiffRendering(characterCount: 500_001))
        #expect(GitDetailDiffDisplayRules.shouldSkipDiffRendering(characterCount: 500_000) == false)
        #expect(GitDetailDiffDisplayRules.diffContentMode(diffText: " \n\t ") == .empty)
        #expect(GitDetailDiffDisplayRules.diffContentMode(diffText: String(repeating: "x", count: 500_001)) == .large)
        #expect(GitDetailDiffDisplayRules.diffContentMode(diffText: "-old\n+new") == .render)
        var copiedIssueMessages: [String] = []
        #expect(GitDetailDiffDisplayRules.performIssueMessageCopy(nil) {
            copiedIssueMessages.append($0)
        } == false)
        #expect(GitDetailDiffDisplayRules.performIssueMessageCopy("") {
            copiedIssueMessages.append($0)
        } == false)
        #expect(GitDetailDiffDisplayRules.performIssueMessageCopy("diff failed") {
            copiedIssueMessages.append($0)
        })
        #expect(copiedIssueMessages == ["diff failed"])
        var copiedRawDiffs: [String] = []
        GitDetailDiffDisplayRules.performRawDiffCopy(diffText: "-old\n+new") {
            copiedRawDiffs.append($0)
        }
        #expect(copiedRawDiffs == ["-old\n+new"])
        let pasteboard = NSPasteboard.withUniqueName()
        #expect(GitDetailPasteboard.writeString("-old\n+new", pasteboard: pasteboard))
        #expect(pasteboard.string(forType: .string) == "-old\n+new")
        #expect(GitDetailImageFactory.image(from: nil) == nil)
        #expect(GitDetailDiffDisplayRules.textPreviewTitle(for: .before, path: "README.md").contains("README.md"))
        #expect(GitDetailDiffDisplayRules.textPreviewState(
            version: .after,
            path: "README.md",
            content: "body"
        ) == .init(title: GitDetailDiffDisplayRules.textPreviewTitle(for: .after, path: "README.md"), content: "body", isPresented: true))
        var previewTitle = ""
        var previewContent = ""
        var previewPresented = false
        GitDetailDiffDisplayRules.performTextPreviewState(
            GitDetailDiffDisplayRules.textPreviewState(
                version: .after,
                path: "README.md",
                content: "body"
            ),
            setTitle: { previewTitle = $0 },
            setContent: { previewContent = $0 },
            setPresented: { previewPresented = $0 }
        )
        #expect(previewTitle == GitDetailDiffDisplayRules.textPreviewTitle(for: .after, path: "README.md"))
        #expect(previewContent == "body")
        #expect(previewPresented)
        #expect(GitDetailDiffDisplayRules.refreshActionOnManualRefresh() == .refresh(
            reason: GitDetailDiffDisplayRules.manualRefreshReason
        ))
        var diffRefreshReasons: [String] = []
        GitDetailDiffDisplayRules.performDiffRefreshAction(
            GitDetailDiffDisplayRules.refreshActionOnManualRefresh()
        ) { reason in
            diffRefreshReasons.append(reason)
        }
        #expect(diffRefreshReasons == [GitDetailDiffDisplayRules.manualRefreshReason])
        var diffRefreshActions: [GitDetailDiffDisplayRules.DiffRefreshAction] = []
        GitDetailDiffDisplayRules.performManualRefresh {
            diffRefreshActions.append($0)
        }
        GitDetailDiffDisplayRules.performFileDidChange {
            diffRefreshActions.append($0)
        }
        GitDetailDiffDisplayRules.performCommitDidChange {
            diffRefreshActions.append($0)
        }
        GitDetailDiffDisplayRules.performFileDetailAppear {
            diffRefreshActions.append($0)
        }
        #expect(diffRefreshActions == [
            GitDetailDiffDisplayRules.refreshActionOnManualRefresh(),
            GitDetailDiffDisplayRules.refreshActionOnFileChanged(),
            GitDetailDiffDisplayRules.refreshActionOnCommitChanged(),
            GitDetailDiffDisplayRules.refreshActionOnAppear(),
        ])
        var appliedDiffText = ""
        var appliedDiffIssueMessage: String?
        GitDetailDiffDisplayRules.performDiffTextState(
            .init(text: "-old\n+new", issueMessage: "large"),
            setText: { appliedDiffText = $0 },
            setIssueMessage: { appliedDiffIssueMessage = $0 }
        )
        #expect(appliedDiffText == "-old\n+new")
        #expect(appliedDiffIssueMessage == "large")
        var requiredFileProjectEvents: [String] = []
        #expect(GitDetailDiffDisplayRules.performRequiredFileAndProject(
            file: Optional<String>.none,
            project: Optional("repo")
        ) { file, project in
            requiredFileProjectEvents.append("\(file):\(project)")
        } == false)
        #expect(GitDetailDiffDisplayRules.performRequiredFileAndProject(
            file: Optional("README.md"),
            project: Optional<String>.none
        ) { file, project in
            requiredFileProjectEvents.append("\(file):\(project)")
        } == false)
        #expect(GitDetailDiffDisplayRules.performRequiredFileAndProject(
            file: Optional("README.md"),
            project: Optional("repo")
        ) { file, project in
            requiredFileProjectEvents.append("\(file):\(project)")
        } == true)
        #expect(requiredFileProjectEvents == ["README.md:repo"])
        var diffTextStates: [GitDetailDiffDisplayRules.DiffTextState] = []
        var diffFailures: [String] = []
        GitDetailDiffDisplayRules.performDiffTextRefreshOperation(
            isBinary: false,
            selectedCommit: "abc",
            existingPatch: "",
            commitHash: { $0 },
            loadCommitDiff: { "commit:\($0)" },
            loadWorktreeDiff: { "worktree" },
            applyDiffTextState: { diffTextStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(diffTextStates == [.init(text: "commit:abc", issueMessage: nil)])
        #expect(diffFailures.isEmpty)
        GitDetailDiffDisplayRules.performDiffTextRefreshOperation(
            isBinary: false,
            selectedCommit: Optional<String>.none,
            existingPatch: "",
            commitHash: { $0 },
            loadCommitDiff: { "commit:\($0)" },
            loadWorktreeDiff: { throw NSError(domain: "GitOKTests", code: 5) },
            applyDiffTextState: { diffTextStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(diffTextStates.last?.issueMessage?.isEmpty == false)
        #expect(diffFailures.count == 1)
        struct DiffFileStub {
            let path: String
            let isBinary: Bool
            let patch: String
        }
        let diffFile = DiffFileStub(path: "README.md", isBinary: false, patch: "")
        var requiredDiffStates: [GitDetailDiffDisplayRules.DiffTextState] = []
        var diffLoaderEvents: [String] = []
        let skippedRequiredDiffRefresh = GitDetailDiffDisplayRules.performRequiredDiffTextRefresh(
            file: Optional<DiffFileStub>.none,
            project: Optional("repo"),
            selectedCommit: Optional("abc"),
            isBinary: \.isBinary,
            existingPatch: \.patch,
            commitHash: { $0 },
            loadCommitDiff: { project, file, hash in
                diffLoaderEvents.append("\(project):\(file.path):\(hash)")
                return "commit"
            },
            loadWorktreeDiff: { project, file in
                diffLoaderEvents.append("\(project):\(file.path):worktree")
                return "worktree"
            },
            applyDiffTextState: { requiredDiffStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(skippedRequiredDiffRefresh == false)
        #expect(diffLoaderEvents.isEmpty)
        #expect(requiredDiffStates.isEmpty)
        let performedRequiredDiffRefresh = GitDetailDiffDisplayRules.performRequiredDiffTextRefresh(
            file: diffFile,
            project: Optional("repo"),
            selectedCommit: Optional("abc"),
            isBinary: \.isBinary,
            existingPatch: \.patch,
            commitHash: { $0 },
            loadCommitDiff: { project, file, hash in
                diffLoaderEvents.append("\(project):\(file.path):\(hash)")
                return "commit:\(hash)"
            },
            loadWorktreeDiff: { project, file in
                diffLoaderEvents.append("\(project):\(file.path):worktree")
                return "worktree"
            },
            applyDiffTextState: { requiredDiffStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(performedRequiredDiffRefresh)
        #expect(diffLoaderEvents == ["repo:README.md:abc"])
        #expect(requiredDiffStates == [.init(text: "commit:abc", issueMessage: nil)])
        diffLoaderEvents = []
        requiredDiffStates = []
        let skippedCommandDiffRefresh = GitDetailDiffDisplayRules.performRequiredDiffTextRefreshCommand(
            file: Optional<DiffFileStub>.none,
            project: Optional("repo"),
            selectedCommit: Optional("abc"),
            isBinary: \.isBinary,
            existingPatch: \.patch,
            commitHash: { $0 },
            loadCommitDiff: { request, hash in
                diffLoaderEvents.append("\(request.project):\(request.file.path):\(hash)")
                return "commit"
            },
            loadWorktreeDiff: { request in
                diffLoaderEvents.append("\(request.project):\(request.file.path):worktree")
                return "worktree"
            },
            applyDiffTextState: { requiredDiffStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(skippedCommandDiffRefresh == false)
        let performedCommandDiffRefresh = GitDetailDiffDisplayRules.performRequiredDiffTextRefreshCommand(
            file: diffFile,
            project: Optional("repo"),
            selectedCommit: Optional("abc"),
            isBinary: \.isBinary,
            existingPatch: \.patch,
            commitHash: { $0 },
            loadCommitDiff: { request, hash in
                diffLoaderEvents.append("\(request.project):\(request.file.path):\(hash)")
                return "command:\(hash)"
            },
            loadWorktreeDiff: { request in
                diffLoaderEvents.append("\(request.project):\(request.file.path):worktree")
                return "worktree"
            },
            applyDiffTextState: { requiredDiffStates.append($0) },
            handleFailure: { diffFailures.append($0) }
        )
        #expect(performedCommandDiffRefresh)
        #expect(diffLoaderEvents == ["repo:README.md:abc"])
        #expect(requiredDiffStates == [.init(text: "command:abc", issueMessage: nil)])
        #expect(GitDetailDiffDisplayRules.diffRefreshFailureLogMessage(errorDescription: "failed").contains("failed"))
        #expect(GitDetailDiffDisplayRules.textPreviewFailureLogMessage(issueMessage: "failed") == "❌ failed")
        #expect(GitDetailDiffDisplayRules.updateDiffViewLogMessage(reason: "Manual") == "🍋 UpdateDiffView(Manual)")
        #expect(GitDetailDiffDisplayRules.refreshActionOnFileChanged() == .refresh(
            reason: GitDetailDiffDisplayRules.fileChangeRefreshReason
        ))
        #expect(GitDetailDiffDisplayRules.refreshActionOnCommitChanged() == .refresh(
            reason: GitDetailDiffDisplayRules.commitChangeRefreshReason
        ))
        #expect(GitDetailDiffDisplayRules.refreshActionOnAppear() == .refresh(
            reason: GitDetailDiffDisplayRules.appearRefreshReason
        ))
        #expect(GitDetailDiffDisplayRules.textPreviewLoadErrorMessage(
            for: .before,
            errorDescription: "failed"
        ).contains("failed"))
        #expect(GitDetailDiffDisplayRules.textPreviewFailureState(
            for: .before,
            errorDescription: "failed"
        ) == .init(
            issueMessage: GitDetailDiffDisplayRules.textPreviewLoadErrorMessage(for: .before, errorDescription: "failed"),
            alertMessage: GitDetailDiffDisplayRules.textPreviewLoadErrorMessage(for: .before, errorDescription: "failed")
        ))
        var textPreviewStates: [GitDetailDiffDisplayRules.TextPreviewState] = []
        var textPreviewFailures: [GitDetailDiffDisplayRules.TextPreviewFailureState] = []
        GitDetailDiffDisplayRules.performTextPreviewLoad(
            version: .after,
            path: "README.md",
            loadContent: { "body" },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewStates == [GitDetailDiffDisplayRules.textPreviewState(
            version: .after,
            path: "README.md",
            content: "body"
        )])
        #expect(textPreviewFailures.isEmpty)
        enum TextPreviewError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "preview failed"
            }
        }
        GitDetailDiffDisplayRules.performTextPreviewLoad(
            version: .before,
            path: "README.md",
            loadContent: { throw TextPreviewError.failed },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewFailures == [GitDetailDiffDisplayRules.textPreviewFailureState(
            for: .before,
            errorDescription: "preview failed"
        )])
        textPreviewStates = []
        textPreviewFailures = []
        GitDetailDiffDisplayRules.performProjectTextPreviewLoad(
            version: .after,
            path: "README.md",
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            selectedCommit: Optional("abc"),
            commitHash: { $0 },
            loadCommitContent: { project, hash in
                (before: nil, after: "\(project):\(hash):after")
            },
            loadWorktreeContent: { project in
                (before: nil, after: "\(project):worktree")
            },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewStates == [GitDetailDiffDisplayRules.textPreviewState(
            version: .after,
            path: "README.md",
            content: "repo:abc:after"
        )])
        #expect(textPreviewFailures.isEmpty)
        textPreviewStates = []
        GitDetailDiffDisplayRules.performProjectTextPreviewLoad(
            version: .after,
            path: "README.md",
            project: Optional<String>.none,
            missingError: GitDetailError.invalidProject,
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            loadCommitContent: { _, _ in (before: nil, after: "ignored") },
            loadWorktreeContent: { _ in (before: nil, after: "ignored") },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewStates.isEmpty)
        #expect(textPreviewFailures.last?.issueMessage.isEmpty == false)
        textPreviewStates = []
        textPreviewFailures = []
        var textPreviewLoadEvents: [String] = []
        GitDetailDiffDisplayRules.performProjectTextPreviewLoadCommand(
            version: .after,
            path: "README.md",
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            file: "README.md",
            selectedCommit: Optional("abc"),
            commitHash: { $0 },
            loadContent: { request in
                textPreviewLoadEvents.append("\(request.project):\(request.file):\(request.source)")
                return (before: nil, after: "command-after")
            },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewStates == [GitDetailDiffDisplayRules.textPreviewState(
            version: .after,
            path: "README.md",
            content: "command-after"
        )])
        #expect(textPreviewFailures.isEmpty)
        GitDetailDiffDisplayRules.performProjectTextPreviewLoadCommand(
            version: .before,
            path: "README.md",
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            file: "README.md",
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            loadContent: { request in
                textPreviewLoadEvents.append("\(request.project):\(request.file):\(request.source)")
                return (before: "command-before", after: nil)
            },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        GitDetailDiffDisplayRules.performProjectTextPreviewLoadCommand(
            version: .after,
            path: "README.md",
            project: Optional<String>.none,
            missingError: GitDetailError.invalidProject,
            file: "README.md",
            selectedCommit: Optional("abc"),
            commitHash: { $0 },
            loadContent: { request in
                textPreviewLoadEvents.append("\(request.project):\(request.file):\(request.source)")
                return (before: nil, after: "ignored")
            },
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewLoadEvents == [
            "repo:README.md:commit(hash: \"abc\")",
            "repo:README.md:worktree",
        ])
        #expect(textPreviewFailures.last?.issueMessage.isEmpty == false)
        textPreviewStates = []
        textPreviewFailures = []
        textPreviewLoadEvents = []
        let textPreviewHandlers = GitDetailDiffDisplayRules.ProjectTextPreviewLoadHandlers<String, String>(
            loadCommitContent: { project, file, hash in
                textPreviewLoadEvents.append("handler-commit:\(project):\(file):\(hash)")
                return (before: nil, after: "handler-after")
            },
            loadWorktreeContent: { project, file in
                textPreviewLoadEvents.append("handler-worktree:\(project):\(file)")
                return (before: "handler-before", after: nil)
            }
        )
        GitDetailDiffDisplayRules.performProjectTextPreviewLoadCommand(
            version: .after,
            path: "README.md",
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            file: "README.md",
            selectedCommit: Optional("abc"),
            commitHash: { $0 },
            handlers: textPreviewHandlers,
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        GitDetailDiffDisplayRules.performProjectTextPreviewLoadCommand(
            version: .before,
            path: "README.md",
            project: Optional("repo"),
            missingError: GitDetailError.invalidProject,
            file: "README.md",
            selectedCommit: Optional<String>.none,
            commitHash: { $0 },
            handlers: textPreviewHandlers,
            applyPreview: { textPreviewStates.append($0) },
            applyFailure: { textPreviewFailures.append($0) }
        )
        #expect(textPreviewLoadEvents == [
            "handler-commit:repo:README.md:abc",
            "handler-worktree:repo:README.md",
        ])
        #expect(textPreviewStates.map(\.content) == ["handler-after", "handler-before"])
        #expect(textPreviewFailures.isEmpty)
        var previewIssueMessage = ""
        var previewAlertMessage = ""
        GitDetailDiffDisplayRules.performTextPreviewFailureState(
            GitDetailDiffDisplayRules.textPreviewFailureState(
                for: .before,
                errorDescription: "preview failed"
            ),
            setIssueMessage: { previewIssueMessage = $0 },
            showError: { previewAlertMessage = $0 }
        )
        #expect(previewIssueMessage.contains("preview failed"))
        #expect(previewAlertMessage == previewIssueMessage)
        #expect(GitDetailDiffDisplayRules.missingTextDescription(for: .before).contains("original"))
        #expect(GitDetailDiffDisplayRules.missingTextDescription(for: .after).contains("new"))
        #expect(GitDetailDiffDisplayRules.textContentOrEmptyPlaceholder("").isEmpty == false)
        #expect(GitDetailDiffDisplayRules.textContentOrEmptyPlaceholder("body") == "body")
        #expect(try GitDetailDiffDisplayRules.textContent(version: .before, before: "", after: "after").isEmpty == false)
        #expect(try GitDetailDiffDisplayRules.textContent(version: .after, before: "before", after: "after") == "after")
        #expect(throws: GitDetailError.self) {
            try GitDetailDiffDisplayRules.textContent(version: .before, before: nil, after: "after")
        }
    }

    @Test("file list rules filter stage and discard text")
    func fileListRules() async throws {
        #expect(FileListRules.normalizedFilterQuery(" src ") == "src")
        #expect(FileListRules.filteredPaths(["Sources/App.swift", "README.md"], query: "source") == ["Sources/App.swift"])
        #expect(FileListRules.filteredPaths(["a", "b"], query: " ") == ["a", "b"])
        #expect(FileListRules.isHistoryMode(hasSelectedCommit: true))
        #expect(FileListRules.isHistoryMode(hasSelectedCommit: false) == false)
        #expect(FileListRules.isHistoryMode(selectedCommit: Optional("commit")))
        #expect(FileListRules.isHistoryMode(selectedCommit: Optional<String>.none) == false)
        #expect(FileListRules.items(
            from: ["a", "b", "c"],
            matching: ["b", "c"],
            path: { $0 }
        ) == ["b", "c"])
        #expect(FileListRules.firstItem(
            matching: "b",
            in: ["a", "b", "c"],
            path: { $0 }
        ) == "b")
        #expect(FileListRules.firstItem(
            matching: "z",
            in: ["a", "b", "c"],
            path: { $0 }
        ) == nil)
        #expect(FileListRules.selectedItem(
            from: .init(
                selectedPath: "b",
                stagedPaths: [],
                unstagedPaths: [],
                untrackedPaths: [],
                selectedBatchPaths: []
            ),
            in: ["a", "b", "c"],
            path: { $0 }
        ) == "b")
        #expect(FileListRules.selectedItem(
            from: .init(
                selectedPath: nil,
                stagedPaths: [],
                unstagedPaths: [],
                untrackedPaths: [],
                selectedBatchPaths: []
            ),
            in: ["a", "b", "c"],
            path: { $0 }
        ) == nil)
        #expect(FileListRules.refreshDebounceInterval == 0.5)
        #expect(FileListRules.hoveredRowOpacity == 0.10)
        #expect(FileListRules.hoverAnimationDuration == 0.12)
        #expect(FileListRules.afterStageFileRefreshReason == "AfterStageFile")
        #expect(FileListRules.afterStageSelectedFilesRefreshReason == "AfterStageSelectedFiles")
        #expect(FileListRules.afterUnstageFileRefreshReason == "AfterUnstageFile")
        #expect(FileListRules.afterUnstageSelectedFilesRefreshReason == "AfterUnstageSelectedFiles")
        #expect(FileListRules.afterDiscardChangesRefreshReason == "AfterDiscardChanges")
        #expect(FileListRules.afterDiscardAllChangesRefreshReason == "AfterDiscardAllChanges")
        #expect(FileListRules.afterDiscardSelectedChangesRefreshReason == "AfterDiscardSelectedChanges")
        #expect(FileListRules.appearRefreshReason == "OnAppear")
        #expect(FileListRules.projectChangedRefreshReason == "OnProjectChanged")
        #expect(FileListRules.commitChangedRefreshReason == "OnCommitChanged")
        #expect(FileListRules.projectDidCommitRefreshReason == "OnProjectDidCommit")
        #expect(FileListRules.projectDidAddFilesRefreshReason == "OnProjectDidAddFiles")
        #expect(FileListRules.gitDirectoryDidChangeRefreshReason == "OnGitDirectoryDidChange")
        #expect(FileListRules.appWillBecomeActiveRefreshReason == "OnAppWillBecomeActive")
        #expect(FileListRules.retryAfterErrorRefreshReason == "RetryAfterError")
        #expect(FileListRules.refreshFileListErrorContext == "refreshFileList")
        #expect(FileListRules.fileOperationFailureLogMessage(failureLogMessage: "Stage failed", errorDescription: "boom") == "❌ Stage failed: boom")
        #expect(FileListRules.refreshSkippedLogMessage(reason: "Manual") == "🚫 Refresh skipped (debounced): Manual")
        #expect(FileListRules.refreshStartedLogMessage(reason: "Manual") == "🍋 Refreshing Manual")
        #expect(FileListRules.commitChangedDuringRefreshLogMessage() == "🔄 Commit changed during refresh, skipping UI update")
        #expect(FileListRules.refreshCancelledLogMessage(reason: "Manual") == "🐜 Refresh cancelled: Manual")
        #expect(FileListRules.refreshFailureLogMessage(errorDescription: "boom") == "❌ Failed to refresh file list: boom")
        #expect(FileListRules.refreshActionOnAppear() == .refresh(reason: FileListRules.appearRefreshReason))
        #expect(FileListRules.refreshActionOnProjectChanged() == .refresh(reason: FileListRules.projectChangedRefreshReason))
        #expect(FileListRules.refreshActionOnCommitChanged() == .refresh(reason: FileListRules.commitChangedRefreshReason))
        #expect(FileListRules.refreshActionOnProjectDidCommit() == .refresh(reason: FileListRules.projectDidCommitRefreshReason))
        #expect(FileListRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: "/repo"))
        #expect(FileListRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: "/other") == false)
        #expect(FileListRules.isCurrentProject(eventProjectPath: "/repo", currentProjectPath: nil) == false)
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(isCurrentProject: true) == .refresh(
            reason: FileListRules.projectDidAddFilesRefreshReason
        ))
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(isCurrentProject: false) == .none)
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        ) == .refresh(reason: FileListRules.projectDidAddFilesRefreshReason))
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(
            eventProjectPath: "/repo",
            currentProjectPath: "/other"
        ) == .none)
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) == .refresh(reason: FileListRules.projectDidAddFilesRefreshReason))
        #expect(FileListRules.refreshActionOnProjectDidAddFiles(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 }
        ) == .none)
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(isCurrentProject: true) == .refresh(
            reason: FileListRules.gitDirectoryDidChangeRefreshReason
        ))
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(isCurrentProject: false) == .none)
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        ) == .refresh(reason: FileListRules.gitDirectoryDidChangeRefreshReason))
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: nil
        ) == .none)
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) == .refresh(reason: FileListRules.gitDirectoryDidChangeRefreshReason))
        #expect(FileListRules.refreshActionOnGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional<String>.none,
            currentProjectPath: { $0 }
        ) == .none)
        #expect(FileListRules.refreshActionOnAppWillBecomeActive() == .refreshImmediately(
            reason: FileListRules.appWillBecomeActiveRefreshReason
        ))
        #expect(FileListRules.refreshAction(for: .appear) == FileListRules.refreshActionOnAppear())
        #expect(FileListRules.refreshAction(for: .projectChanged) == FileListRules.refreshActionOnProjectChanged())
        #expect(FileListRules.refreshAction(for: .commitChanged) == FileListRules.refreshActionOnCommitChanged())
        #expect(FileListRules.refreshAction(for: .projectDidCommit) == FileListRules.refreshActionOnProjectDidCommit())
        #expect(FileListRules.refreshAction(for: .appWillBecomeActive) == FileListRules.refreshActionOnAppWillBecomeActive())
        #expect(FileListRules.refreshAction(for: .projectDidAddFiles(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        )) == .refresh(reason: FileListRules.projectDidAddFilesRefreshReason))
        #expect(FileListRules.refreshAction(for: .projectDidAddFiles(
            eventProjectPath: "/repo",
            currentProjectPath: nil
        )) == .none)
        #expect(FileListRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        )) == .refresh(reason: FileListRules.gitDirectoryDidChangeRefreshReason))
        #expect(FileListRules.refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProjectPath: "/other"
        )) == .none)
        #expect(FileListRules.refreshAction(
            projectDidAddFilesEventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) == .refresh(reason: FileListRules.projectDidAddFilesRefreshReason))
        #expect(FileListRules.refreshAction(
            gitDirectoryChangedEventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) == .refresh(reason: FileListRules.gitDirectoryDidChangeRefreshReason))
        var deferredRefreshReasons: [String] = []
        var immediateRefreshReasons: [String] = []
        FileListRules.performRefreshAction(
            .refresh(reason: "deferred"),
            refresh: { deferredRefreshReasons.append($0) },
            refreshImmediately: { immediateRefreshReasons.append($0) }
        )
        FileListRules.performRefreshAction(
            .refreshImmediately(reason: "immediate"),
            refresh: { deferredRefreshReasons.append($0) },
            refreshImmediately: { immediateRefreshReasons.append($0) }
        )
        FileListRules.performRefreshAction(
            .none,
            refresh: { deferredRefreshReasons.append($0) },
            refreshImmediately: { immediateRefreshReasons.append($0) }
        )
        #expect(deferredRefreshReasons == ["deferred"])
        #expect(immediateRefreshReasons == ["immediate"])
        FileListRules.performRetryAfterError { deferredRefreshReasons.append($0) }
        var fileListEventActions: [FileListRules.RefreshEventAction] = []
        FileListRules.performAppear { fileListEventActions.append($0) }
        FileListRules.performProjectChange { fileListEventActions.append($0) }
        FileListRules.performCommitChange { fileListEventActions.append($0) }
        FileListRules.performProjectDidCommit { fileListEventActions.append($0) }
        FileListRules.performAppWillBecomeActive { fileListEventActions.append($0) }
        FileListRules.performRefreshEvent(.projectDidAddFiles(
            eventProjectPath: "/repo",
            currentProjectPath: "/repo"
        )) { fileListEventActions.append($0) }
        FileListRules.performProjectDidAddFiles(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) { fileListEventActions.append($0) }
        FileListRules.performGitDirectoryChanged(
            eventProjectPath: "/repo",
            currentProject: Optional("/repo"),
            currentProjectPath: { $0 }
        ) { fileListEventActions.append($0) }
        #expect(deferredRefreshReasons == ["deferred", FileListRules.retryAfterErrorRefreshReason])
        #expect(fileListEventActions == [
            FileListRules.refreshActionOnAppear(),
            FileListRules.refreshActionOnProjectChanged(),
            FileListRules.refreshActionOnCommitChanged(),
            FileListRules.refreshActionOnProjectDidCommit(),
            FileListRules.refreshActionOnAppWillBecomeActive(),
            FileListRules.refreshActionOnProjectDidAddFiles(isCurrentProject: true),
            FileListRules.refreshActionOnProjectDidAddFiles(isCurrentProject: true),
            FileListRules.refreshActionOnGitDirectoryChanged(isCurrentProject: true),
        ])
        #expect(FileListRules.shouldRefresh(
            now: Date(timeIntervalSince1970: 10.6),
            lastRefreshTime: Date(timeIntervalSince1970: 10)
        ))
        #expect(FileListRules.shouldRefresh(
            now: Date(timeIntervalSince1970: 10.5),
            lastRefreshTime: Date(timeIntervalSince1970: 10)
        ) == false)
        #expect(FileListRules.currentDate {
            Date(timeIntervalSince1970: 42)
        } == Date(timeIntervalSince1970: 42))
        #expect(FileListRules.refreshRequestState(
            now: Date(timeIntervalSince1970: 10.6),
            lastRefreshTime: Date(timeIntervalSince1970: 10)
        ) == .init(
            shouldStartRefresh: true,
            lastRefreshTime: Date(timeIntervalSince1970: 10.6)
        ))
        #expect(FileListRules.refreshRequestState(
            now: Date(timeIntervalSince1970: 10.5),
            lastRefreshTime: Date(timeIntervalSince1970: 10)
        ) == .init(
            shouldStartRefresh: false,
            lastRefreshTime: Date(timeIntervalSince1970: 10)
        ))
        #expect(FileListRules.refreshRequestState(
            lastRefreshTime: Date(timeIntervalSince1970: 10),
            now: { Date(timeIntervalSince1970: 10.6) }
        ) == .init(
            shouldStartRefresh: true,
            lastRefreshTime: Date(timeIntervalSince1970: 10.6)
        ))
        var refreshRequestEvents: [String] = []
        #expect(FileListRules.performRefreshRequestState(
            .init(shouldStartRefresh: false, lastRefreshTime: Date(timeIntervalSince1970: 10)),
            logSkipped: { refreshRequestEvents.append("skipped") },
            setLastRefreshTime: { refreshRequestEvents.append("last:\($0.timeIntervalSince1970)") },
            cancelPreviousRefreshes: { refreshRequestEvents.append("cancel") },
            startRefresh: { refreshRequestEvents.append("start") }
        ) == false)
        #expect(refreshRequestEvents == ["skipped"])
        #expect(FileListRules.performRefreshRequestState(
            .init(shouldStartRefresh: true, lastRefreshTime: Date(timeIntervalSince1970: 11)),
            logSkipped: { refreshRequestEvents.append("skipped") },
            setLastRefreshTime: { refreshRequestEvents.append("last:\($0.timeIntervalSince1970)") },
            cancelPreviousRefreshes: { refreshRequestEvents.append("cancel") },
            startRefresh: { refreshRequestEvents.append("start") }
        ))
        #expect(refreshRequestEvents == ["skipped", "last:11.0", "cancel", "start"])
        #expect(FileListRules.refreshStartState() == .init(isLoading: true, errorMessage: nil))
        #expect(FileListRules.refreshStoppedState() == .init(isLoading: false, errorMessage: nil))
        #expect(FileListRules.refreshFailedState(errorMessage: "failed") == .init(
            isLoading: false,
            errorMessage: "failed"
        ))
        var requiredRefreshEvents: [String] = []
        #expect(await FileListRules.performRequiredProjectRefresh(
            project: Optional<String>.none,
            applyStartState: { requiredRefreshEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshEvents.append("missing:\($0.isLoading)") },
            refresh: { requiredRefreshEvents.append("refresh:\($0)") }
        ) == false)
        #expect(await FileListRules.performRequiredProjectRefresh(
            project: Optional("repo"),
            applyStartState: { requiredRefreshEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshEvents.append("missing:\($0.isLoading)") },
            refresh: { requiredRefreshEvents.append("refresh:\($0)") }
        ))
        #expect(requiredRefreshEvents == [
            "start:true",
            "missing:false",
            "start:true",
            "refresh:repo",
        ])
        var requiredRefreshRequestEvents: [String] = []
        #expect(await FileListRules.performRequiredProjectRefreshRequest(
            project: Optional<String>.none,
            reason: "Manual",
            applyStartState: { requiredRefreshRequestEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshRequestEvents.append("missing:\($0.isLoading)") },
            refresh: { request, project in requiredRefreshRequestEvents.append("refresh:\(project):\(request.reason)") }
        ) == false)
        #expect(await FileListRules.performRequiredProjectRefreshRequest(
            project: Optional("repo"),
            reason: "Manual",
            applyStartState: { requiredRefreshRequestEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshRequestEvents.append("missing:\($0.isLoading)") },
            refresh: { request, project in requiredRefreshRequestEvents.append("refresh:\(project):\(request.reason)") }
        ))
        #expect(requiredRefreshRequestEvents == [
            "start:true",
            "missing:false",
            "start:true",
            "refresh:repo:Manual",
        ])
        var requiredRefreshCommandEvents: [String] = []
        #expect(await FileListRules.performRequiredProjectRefreshCommand(
            project: Optional<String>.none,
            reason: "Manual",
            applyStartState: { requiredRefreshCommandEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshCommandEvents.append("missing:\($0.isLoading)") },
            refresh: { command in
                requiredRefreshCommandEvents.append("refresh:\(command.project):\(command.request.reason)")
            }
        ) == false)
        #expect(await FileListRules.performRequiredProjectRefreshCommand(
            project: Optional("repo"),
            reason: "Manual",
            applyStartState: { requiredRefreshCommandEvents.append("start:\($0.isLoading)") },
            applyMissingProjectState: { requiredRefreshCommandEvents.append("missing:\($0.isLoading)") },
            refresh: { command in
                requiredRefreshCommandEvents.append("refresh:\(command.project):\(command.request.reason)")
            }
        ))
        #expect(requiredRefreshCommandEvents == [
            "start:true",
            "missing:false",
            "start:true",
            "refresh:repo:Manual",
        ])
        #expect(FileListRules.rowBackgroundState(isHovered: true) == .hovered)
        #expect(FileListRules.rowBackgroundState(isHovered: false) == .clear)
        #expect(FileListRules.stageState(
            path: "a",
            stagedPaths: ["a"],
            unstagedPaths: ["a"]
        ) == .stagedAndUnstaged)
        #expect(FileListRules.stageState(
            path: "a",
            stagedPaths: ["a"],
            unstagedPaths: []
        ) == .staged)
        #expect(FileListRules.stageState(
            path: "a",
            stagedPaths: [],
            unstagedPaths: ["a"]
        ) == .unstaged)
        #expect(FileListRules.discardSelectedAlertMessage(selectedCount: 3, untrackedCount: 1).contains("1 untracked"))
        #expect(FileListRules.discardFileAlertMessage(path: "README.md", isUntracked: false).contains("README.md"))
        #expect(FileListRules.discardFileAlertMessage(path: "README.md", isUntracked: true).contains("untracked file"))
        #expect(FileListRules.discardFileAlertMessage(
            path: "README.md",
            untrackedPaths: ["README.md"]
        ).contains("untracked file"))
        #expect(FileListRules.discardFileAlertMessage(
            path: "README.md",
            untrackedPaths: ["Sources/App.swift"]
        ).contains("untracked file") == false)
        #expect(FileListRules.discardFileAlertMessage(
            file: Optional<(path: String, index: Int)>.none,
            path: \.path,
            untrackedPaths: ["README.md"]
        ).isEmpty)
        #expect(FileListRules.discardFileAlertMessage(
            file: Optional((path: "README.md", index: 0)),
            path: \.path,
            untrackedPaths: ["README.md"]
        ).contains("untracked file"))
        #expect(FileListRules.discardAllAlertMessage(
            totalFileCount: 4,
            stagedCount: 1,
            unstagedCount: 2,
            untrackedCount: 1
        ).contains("1 staged"))
        let discardAllAlertText = FileListRules.discardAllAlertText()
        #expect(discardAllAlertText.title.isEmpty == false)
        #expect(discardAllAlertText.cancelButtonTitle.isEmpty == false)
        #expect(discardAllAlertText.destructiveButtonTitle.isEmpty == false)
        let discardSelectedAlertText = FileListRules.discardSelectedAlertText()
        #expect(discardSelectedAlertText.title.isEmpty == false)
        #expect(discardSelectedAlertText.cancelButtonTitle.isEmpty == false)
        #expect(discardSelectedAlertText.destructiveButtonTitle.isEmpty == false)
        let discardFileAlertText = FileListRules.discardFileAlertText()
        #expect(discardFileAlertText.title.isEmpty == false)
        #expect(discardFileAlertText.cancelButtonTitle.isEmpty == false)
        #expect(discardFileAlertText.destructiveButtonTitle.isEmpty == false)
        #expect(FileListRules.stagedFileMessage(path: "README.md").contains("README.md"))
        #expect(FileListRules.stagedFilesMessage(count: 2).contains("2"))
        #expect(FileListRules.unstagedFileMessage(path: "README.md").contains("README.md"))
        #expect(FileListRules.unstagedFilesMessage(count: 2).contains("2"))
        #expect(FileListRules.discardedFileChangesMessage(path: "README.md").contains("README.md"))
        #expect(FileListRules.discardedAllChangesMessage().isEmpty == false)
        #expect(FileListRules.discardedSelectedChangesMessage(count: 2).contains("2"))
        #expect(FileListRules.stageFileSuccessState(path: "README.md").refreshReason == FileListRules.afterStageFileRefreshReason)
        #expect(FileListRules.stageFileSuccessState(path: "README.md").removesBatchSelectionPaths.isEmpty)
        #expect(FileListRules.stageSelectedFilesSuccessState(paths: ["a", "b"]) == .init(
            message: FileListRules.stagedFilesMessage(count: 2),
            refreshReason: FileListRules.afterStageSelectedFilesRefreshReason,
            removesBatchSelectionPaths: ["a", "b"]
        ))
        #expect(FileListRules.unstageFileSuccessState(path: "README.md").refreshReason == FileListRules.afterUnstageFileRefreshReason)
        #expect(FileListRules.unstageSelectedFilesSuccessState(paths: ["a"]) == .init(
            message: FileListRules.unstagedFilesMessage(count: 1),
            refreshReason: FileListRules.afterUnstageSelectedFilesRefreshReason,
            removesBatchSelectionPaths: ["a"]
        ))
        #expect(FileListRules.discardFileChangesSuccessState(path: "README.md").refreshReason == FileListRules.afterDiscardChangesRefreshReason)
        #expect(FileListRules.discardAllChangesSuccessState() == .init(
            message: FileListRules.discardedAllChangesMessage(),
            refreshReason: FileListRules.afterDiscardAllChangesRefreshReason,
            removesBatchSelectionPaths: []
        ))
        #expect(FileListRules.discardSelectedChangesSuccessState(paths: ["a", "b"]) == .init(
            message: FileListRules.discardedSelectedChangesMessage(count: 2),
            refreshReason: FileListRules.afterDiscardSelectedChangesRefreshReason,
            removesBatchSelectionPaths: ["a", "b"]
        ))
        #expect(FileListRules.operationCompletionState(
            successState: FileListRules.discardSelectedChangesSuccessState(paths: ["a", "b"]),
            selectedBatchPaths: ["a", "b", "c"]
        ) == .init(
            message: FileListRules.discardedSelectedChangesMessage(count: 2),
            selectedBatchPaths: ["c"]
        ))
        #expect(FileListRules.operationCompletionState(
            successState: FileListRules.stageFileSuccessState(path: "README.md"),
            selectedBatchPaths: ["a"]
        ).selectedBatchPaths == ["a"])
        var operationMessages: [String] = []
        var operationSelections: [Set<String>] = []
        FileListRules.performOperationSuccessState(
            FileListRules.discardSelectedChangesSuccessState(paths: ["a", "b"]),
            selectedBatchPaths: ["a", "b", "c"],
            showMessage: { operationMessages.append($0) },
            setSelectedBatchPaths: { operationSelections.append($0) }
        )
        #expect(operationMessages == [FileListRules.discardedSelectedChangesMessage(count: 2)])
        #expect(operationSelections == [["c"]])
        #expect(FileListRules.singleFileOperationRequest(path: "README.md") == .init(paths: ["README.md"]))
        #expect(FileListRules.FileOperationRequestState(paths: []).canPerform == false)
        #expect(FileListRules.FileOperationRequestState(paths: []).primaryPath == nil)
        #expect(FileListRules.FileOperationRequestState(paths: ["README.md"]).canPerform)
        #expect(FileListRules.FileOperationRequestState(paths: ["README.md"]).primaryPath == "README.md")
        var performedFileRequests: [FileListRules.FileOperationRequestState] = []
        #expect(FileListRules.performFileOperationRequest(
            FileListRules.FileOperationRequestState(paths: []),
            perform: { performedFileRequests.append($0) }
        ) == false)
        #expect(performedFileRequests.isEmpty)
        #expect(FileListRules.performFileOperationRequest(
            FileListRules.FileOperationRequestState(paths: ["README.md"]),
            perform: { performedFileRequests.append($0) }
        ))
        #expect(performedFileRequests == [FileListRules.FileOperationRequestState(paths: ["README.md"])])
        var performedPrimaryPaths: [String] = []
        #expect(FileListRules.performPrimaryFileOperationRequest(
            FileListRules.FileOperationRequestState(paths: []),
            perform: { performedPrimaryPaths.append($0) }
        ) == false)
        #expect(performedPrimaryPaths.isEmpty)
        #expect(FileListRules.performPrimaryFileOperationRequest(
            FileListRules.FileOperationRequestState(paths: ["README.md"]),
            perform: { performedPrimaryPaths.append($0) }
        ))
        #expect(performedPrimaryPaths == ["README.md"])
        var operationRequests: [FileListRules.FileOperationRequestState] = []
        var appliedOperationStates: [FileListRules.OperationSuccessState] = []
        var operationRefreshReasons: [String] = []
        var operationFailures: [String] = []
        await FileListRules.performFileOperation(
            FileListRules.FileOperationRequestState(paths: ["README.md"]),
            operation: { request in
                operationRequests.append(request)
                return FileListRules.stageFileSuccessState(path: request.paths[0])
            },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(operationRequests == [FileListRules.FileOperationRequestState(paths: ["README.md"])])
        #expect(appliedOperationStates == [FileListRules.stageFileSuccessState(path: "README.md")])
        #expect(operationRefreshReasons == [FileListRules.afterStageFileRefreshReason])
        #expect(operationFailures.isEmpty)
        await FileListRules.performFileOperation(
            FileListRules.FileOperationRequestState(paths: []),
            operation: { request in
                operationRequests.append(request)
                return FileListRules.stageFileSuccessState(path: "unused")
            },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(operationRequests == [FileListRules.FileOperationRequestState(paths: ["README.md"])])
        enum OperationError: Error, LocalizedError {
            case failed

            var errorDescription: String? {
                "failed"
            }
        }
        await FileListRules.performFileOperation(
            FileListRules.FileOperationRequestState(paths: ["BROKEN.md"]),
            operation: { _ in throw OperationError.failed },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(operationFailures == ["failed"])
        #expect(operationRefreshReasons == [FileListRules.afterStageFileRefreshReason])
        var unconditionalOperationRuns = 0
        await FileListRules.performFileOperation(
            operation: {
                unconditionalOperationRuns += 1
                return FileListRules.discardAllChangesSuccessState()
            },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(unconditionalOperationRuns == 1)
        #expect(appliedOperationStates.last == FileListRules.discardAllChangesSuccessState())
        #expect(operationRefreshReasons.last == FileListRules.afterDiscardAllChangesRefreshReason)
        await FileListRules.performFileOperation(
            operation: { throw OperationError.failed },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(operationFailures == ["failed", "failed"])
        var performedFileOperations: [String] = []
        #expect(try FileListRules.performStageFiles(
            .init(paths: ["README.md"]),
            addFiles: { performedFileOperations.append("stage:\($0.joined(separator: ","))") }
        ) == FileListRules.stageFileSuccessState(path: "README.md"))
        #expect(try FileListRules.performStageFiles(
            .init(paths: ["a.swift", "b.swift"]),
            addFiles: { performedFileOperations.append("stage:\($0.joined(separator: ","))") }
        ) == FileListRules.stageSelectedFilesSuccessState(paths: ["a.swift", "b.swift"]))
        #expect(try FileListRules.performUnstageFiles(
            .init(paths: ["README.md"]),
            unstageFiles: { performedFileOperations.append("unstage:\($0.joined(separator: ","))") }
        ) == FileListRules.unstageFileSuccessState(path: "README.md"))
        #expect(try FileListRules.performUnstageFiles(
            .init(paths: ["a.swift", "b.swift"]),
            unstageFiles: { performedFileOperations.append("unstage:\($0.joined(separator: ","))") }
        ) == FileListRules.unstageSelectedFilesSuccessState(paths: ["a.swift", "b.swift"]))
        #expect(try FileListRules.performDiscardFileChanges(
            .init(paths: ["README.md"]),
            discard: { performedFileOperations.append("discard:\($0)") }
        ) == FileListRules.discardFileChangesSuccessState(path: "README.md"))
        #expect(try FileListRules.performDiscardSelectedChanges(
            .init(paths: ["a.swift", "b.swift"]),
            discard: { performedFileOperations.append("discard:\($0)") }
        ) == FileListRules.discardSelectedChangesSuccessState(paths: ["a.swift", "b.swift"]))
        #expect(performedFileOperations == [
            "stage:README.md",
            "stage:a.swift,b.swift",
            "unstage:README.md",
            "unstage:a.swift,b.swift",
            "discard:README.md",
            "discard:a.swift",
            "discard:b.swift",
        ])
        performedFileOperations = []
        appliedOperationStates = []
        operationRefreshReasons = []
        operationFailures = []
        await FileListRules.performStageFileOperation(
            .init(paths: ["a.swift", "b.swift"]),
            addFiles: { performedFileOperations.append("stage:\($0.joined(separator: ","))") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        await FileListRules.performUnstageFileOperation(
            .init(paths: ["a.swift"]),
            unstageFiles: { performedFileOperations.append("unstage:\($0.joined(separator: ","))") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        await FileListRules.performDiscardFileOperation(
            .init(paths: ["README.md"]),
            discard: { performedFileOperations.append("discard:\($0)") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        await FileListRules.performDiscardAllChangesOperation(
            discardAllChanges: { performedFileOperations.append("discard-all") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        await FileListRules.performDiscardSelectedChangesOperation(
            .init(paths: ["one", "two"]),
            discard: { performedFileOperations.append("discard-selected:\($0)") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(performedFileOperations == [
            "stage:a.swift,b.swift",
            "unstage:a.swift",
            "discard:README.md",
            "discard-all",
            "discard-selected:one",
            "discard-selected:two",
        ])
        #expect(appliedOperationStates == [
            FileListRules.stageSelectedFilesSuccessState(paths: ["a.swift", "b.swift"]),
            FileListRules.unstageFileSuccessState(path: "a.swift"),
            FileListRules.discardFileChangesSuccessState(path: "README.md"),
            FileListRules.discardAllChangesSuccessState(),
            FileListRules.discardSelectedChangesSuccessState(paths: ["one", "two"]),
        ])
        #expect(operationRefreshReasons == [
            FileListRules.afterStageSelectedFilesRefreshReason,
            FileListRules.afterUnstageFileRefreshReason,
            FileListRules.afterDiscardChangesRefreshReason,
            FileListRules.afterDiscardAllChangesRefreshReason,
            FileListRules.afterDiscardSelectedChangesRefreshReason,
        ])
        #expect(operationFailures.isEmpty)
        performedFileOperations = []
        appliedOperationStates = []
        operationRefreshReasons = []
        operationFailures = []
        await FileListRules.performFileOperation(
            kind: .stage,
            request: .init(paths: ["one.swift"]),
            addFiles: { performedFileOperations.append("stage:\($0.joined(separator: ","))") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        await FileListRules.performFileOperation(
            kind: .discardAll,
            discardAllChanges: { performedFileOperations.append("discard-all") },
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { operationFailures.append($0.localizedDescription) }
        )
        #expect(performedFileOperations == [
            "stage:one.swift",
            "discard-all",
        ])
        #expect(appliedOperationStates == [
            FileListRules.stageFileSuccessState(path: "one.swift"),
            FileListRules.discardAllChangesSuccessState(),
        ])
        #expect(operationRefreshReasons == [
            FileListRules.afterStageFileRefreshReason,
            FileListRules.afterDiscardAllChangesRefreshReason,
        ])
        #expect(operationFailures.isEmpty)
        performedFileOperations = []
        appliedOperationStates = []
        operationRefreshReasons = []
        var commandFailures: [String] = []
        let fileOperationHandlers = FileListRules.FileOperationHandlers(
            addFiles: { performedFileOperations.append("stage:\($0.joined(separator: ","))") },
            unstageFiles: { paths in
                if paths == ["broken.swift"] {
                    throw OperationError.failed
                }
                performedFileOperations.append("unstage:\(paths.joined(separator: ","))")
            },
            discard: { performedFileOperations.append("discard:\($0)") },
            discardAllChanges: { performedFileOperations.append("discard-all") }
        )
        await FileListRules.performFileOperation(
            command: FileListRules.stageFileOperationCommand(path: "command.swift"),
            handlers: fileOperationHandlers,
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { message, error in commandFailures.append("\(message):\(error.localizedDescription)") }
        )
        await FileListRules.performFileOperation(
            command: FileListRules.unstageFileOperationCommand(path: "broken.swift"),
            handlers: fileOperationHandlers,
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { message, error in commandFailures.append("\(message):\(error.localizedDescription)") }
        )
        #expect(performedFileOperations == ["stage:command.swift"])
        #expect(appliedOperationStates == [FileListRules.stageFileSuccessState(path: "command.swift")])
        #expect(operationRefreshReasons == [FileListRules.afterStageFileRefreshReason])
        #expect(commandFailures == ["Unstage file failed:failed"])
        performedFileOperations = []
        appliedOperationStates = []
        operationRefreshReasons = []
        commandFailures = []
        let projectFileOperationHandlers = FileListRules.ProjectFileOperationHandlers<String>(
            addFiles: { project, paths in performedFileOperations.append("\(project):stage:\(paths.joined(separator: ","))") },
            unstageFiles: { project, paths in performedFileOperations.append("\(project):unstage:\(paths.joined(separator: ","))") },
            discard: { project, path in
                if path == "broken.swift" {
                    throw OperationError.failed
                }
                performedFileOperations.append("\(project):discard:\(path)")
            },
            discardAllChanges: { project in performedFileOperations.append("\(project):discard-all") }
        )
        await FileListRules.performFileOperation(
            projectCommand: FileListRules.ProjectFileOperationCommand(
                command: FileListRules.stageFileOperationCommand(path: "project-command.swift"),
                project: "repo"
            ),
            handlers: projectFileOperationHandlers,
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { message, error in commandFailures.append("\(message):\(error.localizedDescription)") }
        )
        await FileListRules.performFileOperation(
            projectCommand: FileListRules.ProjectFileOperationCommand(
                command: FileListRules.discardFileOperationCommand(path: "broken.swift"),
                project: "repo"
            ),
            handlers: projectFileOperationHandlers,
            applySuccess: { appliedOperationStates.append($0) },
            refresh: { operationRefreshReasons.append($0) },
            handleFailure: { message, error in commandFailures.append("\(message):\(error.localizedDescription)") }
        )
        #expect(performedFileOperations == ["repo:stage:project-command.swift"])
        #expect(appliedOperationStates == [FileListRules.stageFileSuccessState(path: "project-command.swift")])
        #expect(operationRefreshReasons == [FileListRules.afterStageFileRefreshReason])
        #expect(commandFailures == ["Failed to discard file changes:failed"])
        #expect(FileListRules.refreshedSelectionPath(
            preferredPath: "b",
            newPaths: ["a", "b", "c"]
        ) == "b")
        #expect(FileListRules.refreshedSelectionPath(
            preferredPath: "z",
            newPaths: ["a", "b"]
        ) == "a")
        #expect(FileListRules.selectedBatchPathsAfterRefresh(
            selectedPaths: ["a", "z"],
            newPaths: ["a", "b"]
        ) == ["a"])
        let refreshState = FileListRules.refreshState(
            preferredPath: "b",
            newPaths: ["a", "b", "c"],
            statusEntries: [
                (path: "a", indexStatus: "M", workTreeStatus: " "),
                (path: "b", indexStatus: " ", workTreeStatus: "M"),
                (path: "c", indexStatus: "?", workTreeStatus: " "),
            ],
            selectedBatchPaths: ["b", "z"]
        )
        #expect(refreshState.selectedPath == "b")
        #expect(refreshState.stagedPaths == ["a"])
        #expect(refreshState.unstagedPaths == ["b", "c"])
        #expect(refreshState.untrackedPaths == ["c"])
        #expect(refreshState.selectedBatchPaths == ["b"])
        #expect(FileListRules.shouldApplyRefreshResult(
            expectedCommitHash: "abc123",
            currentCommitHash: "abc123"
        ))
        #expect(FileListRules.shouldApplyRefreshResult(
            expectedCommitHash: nil,
            currentCommitHash: nil
        ))
        #expect(FileListRules.shouldApplyRefreshResult(
            expectedCommitHash: "abc123",
            currentCommitHash: "def456"
        ) == false)
        #expect(FileListRules.selectedCommitHash(
            selectedCommit: (hash: "abc123", index: 0),
            hash: \.hash
        ) == "abc123")
        #expect(FileListRules.selectedCommitHash(
            selectedCommit: nil as (hash: String, index: Int)?,
            hash: \.hash
        ) == nil)
        let historyRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: "abc123",
            loadCommitFiles: { hash in ["history:\(hash)"] },
            loadWorktreeFiles: { ["worktree"] },
            loadStatusEntries: { ["status"] }
        )
        #expect(historyRefreshLoad.files == ["history:abc123"])
        #expect(historyRefreshLoad.selectedCommitHash == "abc123")
        #expect(historyRefreshLoad.statusEntries.isEmpty)
        let worktreeRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: nil,
            loadCommitFiles: { hash in ["history:\(hash)"] },
            loadWorktreeFiles: { ["worktree"] },
            loadStatusEntries: { ["status"] }
        )
        #expect(worktreeRefreshLoad.files == ["worktree"])
        #expect(worktreeRefreshLoad.selectedCommitHash == nil)
        #expect(worktreeRefreshLoad.statusEntries == ["status"])
        let refreshLoadHandlers = FileListRules.RefreshLoadHandlers<String, String>(
            loadCommitFiles: { hash in ["handler-history:\(hash)"] },
            loadWorktreeFiles: { ["handler-worktree"] },
            loadStatusEntries: { ["handler-status"] }
        )
        let handlerHistoryRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: "abc123",
            handlers: refreshLoadHandlers
        )
        #expect(handlerHistoryRefreshLoad.files == ["handler-history:abc123"])
        #expect(handlerHistoryRefreshLoad.statusEntries.isEmpty)
        let handlerWorktreeRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: nil,
            handlers: refreshLoadHandlers
        )
        #expect(handlerWorktreeRefreshLoad.files == ["handler-worktree"])
        #expect(handlerWorktreeRefreshLoad.statusEntries == ["handler-status"])
        let projectRefreshLoadHandlers = FileListRules.ProjectRefreshLoadHandlers<String, String, String>(
            loadCommitFiles: { project, hash in ["\(project)-history:\(hash)"] },
            loadWorktreeFiles: { project in ["\(project)-worktree"] },
            loadStatusEntries: { project in ["\(project)-status"] }
        )
        let projectHistoryRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: "def456",
            handlers: FileListRules.refreshLoadHandlers(for: "repo", handlers: projectRefreshLoadHandlers)
        )
        #expect(projectHistoryRefreshLoad.files == ["repo-history:def456"])
        #expect(projectHistoryRefreshLoad.statusEntries.isEmpty)
        let projectWorktreeRefreshLoad = try await FileListRules.performRefreshLoad(
            selectedCommitHash: nil,
            handlers: FileListRules.refreshLoadHandlers(for: "repo", handlers: projectRefreshLoadHandlers)
        )
        #expect(projectWorktreeRefreshLoad.files == ["repo-worktree"])
        #expect(projectWorktreeRefreshLoad.statusEntries == ["repo-status"])
        #expect(FileListRules.refreshResultApplicationState(
            expectedCommitHash: "abc123",
            currentCommitHash: "abc123",
            preferredPath: "b",
            newPaths: ["a", "b", "c"],
            statusEntries: [
                (path: "a", indexStatus: "M", workTreeStatus: " "),
                (path: "b", indexStatus: " ", workTreeStatus: "M"),
                (path: "c", indexStatus: "?", workTreeStatus: " "),
            ],
            selectedBatchPaths: ["b", "z"]
        ) == .init(shouldApply: true, refreshState: refreshState))
        #expect(FileListRules.refreshResultApplicationState(
            expectedCommitHash: "abc123",
            currentCommitHash: "abc123",
            preferredPath: "b",
            newItems: [(path: "a", index: 0), (path: "b", index: 1), (path: "c", index: 2)],
            itemPath: \.path,
            statusEntries: [
                (path: "a", indexStatus: "M", workTreeStatus: " "),
                (path: "b", indexStatus: " ", workTreeStatus: "M"),
                (path: "c", indexStatus: "?", workTreeStatus: " "),
            ],
            statusPath: \.path,
            indexStatus: \.indexStatus,
            workTreeStatus: \.workTreeStatus,
            selectedBatchPaths: ["b", "z"]
        ) == .init(shouldApply: true, refreshState: refreshState))
        #expect(FileListRules.refreshResultApplicationState(
            expectedCommitHash: "abc123",
            currentCommitHash: "def456",
            preferredPath: "b",
            newPaths: ["a", "b", "c"],
            statusEntries: [
                (path: "a", indexStatus: "M", workTreeStatus: " "),
            ],
            selectedBatchPaths: ["b", "z"]
        ) == .init(shouldApply: false, refreshState: nil))
        var refreshApplicationEvents: [String] = []
        FileListRules.performRefreshResultApplicationState(
            .init(shouldApply: true, refreshState: refreshState),
            newItems: [(path: "a", index: 0), (path: "b", index: 1), (path: "c", index: 2)],
            itemPath: \.path,
            apply: { items, state, selected in
                refreshApplicationEvents.append("apply:\(items.count):\(state.selectedPath ?? ""):\(selected?.path ?? "")")
            },
            skip: { refreshApplicationEvents.append("skip") }
        )
        FileListRules.performRefreshResultApplicationState(
            .init(shouldApply: false, refreshState: nil),
            newItems: [(path: "a", index: 0)],
            itemPath: \.path,
            apply: { _, _, _ in refreshApplicationEvents.append("apply") },
            skip: { refreshApplicationEvents.append("skip") }
        )
        #expect(refreshApplicationEvents == ["apply:3:b:b", "skip"])
        var refreshedItems: [String] = []
        var refreshedStagedPaths: Set<String> = []
        var refreshedUnstagedPaths: Set<String> = []
        var refreshedUntrackedPaths: Set<String> = []
        var refreshedBatchPaths: Set<String> = []
        var refreshedSelection: String?
        var syncedSelection: String?
        var refreshLifecycleStates: [FileListRules.RefreshLifecycleState] = []
        FileListRules.performRefreshResultState(
            items: ["a", "b", "c"],
            refreshState: refreshState,
            refreshedSelection: "b",
            setItems: { refreshedItems = $0 },
            setStagedPaths: { refreshedStagedPaths = $0 },
            setUnstagedPaths: { refreshedUnstagedPaths = $0 },
            setUntrackedPaths: { refreshedUntrackedPaths = $0 },
            setSelectedBatchPaths: { refreshedBatchPaths = $0 },
            setSelection: { refreshedSelection = $0 },
            syncSelection: { syncedSelection = $0 },
            applyLifecycleState: { refreshLifecycleStates.append($0) }
        )
        #expect(refreshedItems == ["a", "b", "c"])
        #expect(refreshedStagedPaths == ["a"])
        #expect(refreshedUnstagedPaths == ["b", "c"])
        #expect(refreshedUntrackedPaths == ["c"])
        #expect(refreshedBatchPaths == ["b"])
        #expect(refreshedSelection == "b")
        #expect(syncedSelection == "b")
        #expect(refreshLifecycleStates == [FileListRules.refreshStoppedState()])
        var appliedRefreshLoading: Bool?
        var appliedRefreshError: String?
        FileListRules.performRefreshLifecycleState(
            FileListRules.refreshFailedState(errorMessage: "boom"),
            setLoading: { appliedRefreshLoading = $0 },
            setErrorMessage: { appliedRefreshError = $0 }
        )
        #expect(appliedRefreshLoading == false)
        #expect(appliedRefreshError == "boom")
        var refreshOperationEvents: [String] = []
        try await FileListRules.performRefreshOperation(
            selectedCommitHash: nil,
            loadCommitFiles: { ["history:\($0)"] },
            loadWorktreeFiles: { ["a", "b"] },
            loadStatusEntries: {
                [
                    (path: "a", indexStatus: "M", workTreeStatus: " "),
                    (path: "b", indexStatus: " ", workTreeStatus: "M"),
                ]
            },
            currentCommitHash: { nil },
            preferredPath: { "b" },
            selectedBatchPaths: { ["a", "z"] },
            itemPath: { $0 },
            statusPath: \.path,
            indexStatus: \.indexStatus,
            workTreeStatus: \.workTreeStatus,
            apply: { items, state, selected in
                refreshOperationEvents.append("apply:\(items.joined(separator: ",")):\(state.selectedPath ?? ""):\(selected ?? ""):\(state.selectedBatchPaths.sorted().joined(separator: ","))")
            },
            skip: {
                refreshOperationEvents.append("skip")
            }
        )
        try await FileListRules.performRefreshOperation(
            selectedCommitHash: "old",
            loadCommitFiles: { ["history:\($0)"] },
            loadWorktreeFiles: { ["worktree"] },
            loadStatusEntries: { [] as [(path: String, indexStatus: String, workTreeStatus: String)] },
            currentCommitHash: { "new" },
            preferredPath: { nil },
            selectedBatchPaths: { [] },
            itemPath: { $0 },
            statusPath: \.path,
            indexStatus: \.indexStatus,
            workTreeStatus: \.workTreeStatus,
            apply: { _, _, _ in
                refreshOperationEvents.append("apply")
            },
            skip: {
                refreshOperationEvents.append("skip")
            }
        )
        try await FileListRules.performRefreshOperation(
            selectedCommitHash: nil,
            handlers: FileListRules.RefreshLoadHandlers<String, (path: String, indexStatus: String, workTreeStatus: String)>(
                loadCommitFiles: { ["handler-history:\($0)"] },
                loadWorktreeFiles: { ["handler-a", "handler-b"] },
                loadStatusEntries: {
                    [
                        (path: "handler-a", indexStatus: "M", workTreeStatus: " "),
                        (path: "handler-b", indexStatus: " ", workTreeStatus: "M"),
                    ]
                }
            ),
            currentCommitHash: { nil },
            preferredPath: { "handler-b" },
            selectedBatchPaths: { ["handler-a"] },
            itemPath: { $0 },
            statusPath: \.path,
            indexStatus: \.indexStatus,
            workTreeStatus: \.workTreeStatus,
            apply: { items, state, selected in
                refreshOperationEvents.append("handler:\(items.joined(separator: ",")):\(state.selectedPath ?? ""):\(selected ?? "")")
            },
            skip: {
                refreshOperationEvents.append("handler-skip")
            }
        )
        try await FileListRules.performRefreshOperation(
            command: FileListRules.ProjectRefreshCommand(
                request: FileListRules.ProjectRefreshRequest(reason: "project-refresh"),
                project: "repo"
            ),
            selectedCommitHash: nil,
            handlers: FileListRules.ProjectRefreshLoadHandlers<String, String, (path: String, indexStatus: String, workTreeStatus: String)>(
                loadCommitFiles: { project, hash in ["\(project)-history:\(hash)"] },
                loadWorktreeFiles: { project in ["\(project)-a", "\(project)-b"] },
                loadStatusEntries: { project in
                    [
                        (path: "\(project)-a", indexStatus: "M", workTreeStatus: " "),
                        (path: "\(project)-b", indexStatus: " ", workTreeStatus: "M"),
                    ]
                }
            ),
            currentCommitHash: { nil },
            preferredPath: { "repo-b" },
            selectedBatchPaths: { ["repo-a"] },
            itemPath: { $0 },
            statusPath: \.path,
            indexStatus: \.indexStatus,
            workTreeStatus: \.workTreeStatus,
            apply: { items, state, selected in
                refreshOperationEvents.append("project:\(items.joined(separator: ",")):\(state.selectedPath ?? ""):\(selected ?? "")")
            },
            skip: {
                refreshOperationEvents.append("project-skip")
            }
        )
        #expect(refreshOperationEvents == [
            "apply:a,b:b:b:a",
            "skip",
            "handler:handler-a,handler-b:handler-b:handler-b",
            "project:repo-a,repo-b:repo-b:repo-b",
        ])
        #expect(FileListRules.batchSelectionPathsAfterToggle(
            currentSelection: ["a"],
            path: "a"
        ).isEmpty)
        #expect(FileListRules.batchSelectionPathsAfterToggle(
            currentSelection: ["a"],
            path: "b"
        ) == ["a", "b"])
        var toggledBatchSelection: Set<String> = []
        FileListRules.performBatchSelectionToggle(
            currentSelection: ["a"],
            path: "b",
            setSelectedBatchPaths: { toggledBatchSelection = $0 }
        )
        #expect(toggledBatchSelection == ["a", "b"])
        #expect(FileListRules.batchSelectionPathsAfterSelectAll(
            currentSelection: ["a"],
            visiblePaths: ["b", "c"]
        ) == ["a", "b", "c"])
        var selectedAllBatchSelection: Set<String> = []
        FileListRules.performBatchSelectionSelectAll(
            currentSelection: ["a"],
            presentationState: .init(
                visiblePaths: ["b", "c"],
                sections: [],
                batchActionState: .init(
                    selectedPaths: [],
                    stageablePaths: [],
                    unstageablePaths: [],
                    untrackedCount: 0
                ),
                discardAllAlertMessage: "",
                discardSelectedAlertMessage: "",
                showsDiscardAll: false,
                showsBatchActionBar: false,
                canSelectAll: true,
                showsEmptyState: false,
                emptyStateIsFiltering: false
            ),
            setSelectedBatchPaths: { selectedAllBatchSelection = $0 }
        )
        #expect(selectedAllBatchSelection == ["a", "b", "c"])
        #expect(FileListRules.batchSelectionPathsAfterClear().isEmpty)
        var clearedBatchSelection: Set<String> = ["stale"]
        FileListRules.performBatchSelectionClear {
            clearedBatchSelection = $0
        }
        #expect(clearedBatchSelection.isEmpty)
        #expect(FileListRules.nextSelectionPath(
            currentPath: nil,
            visiblePaths: ["a", "b"],
            direction: .down
        ) == "a")
        #expect(FileListRules.nextSelectionPath(
            currentPath: "b",
            visiblePaths: ["a", "b"],
            direction: .down
        ) == "b")
        #expect(FileListRules.nextSelectionPath(
            currentPath: "b",
            visiblePaths: ["a", "b"],
            direction: .up
        ) == "a")
        let selectionPresentationState = FileListRules.presentationState(
            allPaths: ["a", "b", "c"],
            filterText: "",
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: ["a", "b", "c"],
            untrackedPaths: [],
            selectedBatchPaths: []
        )
        #expect(FileListRules.nextSelectionItem(
            currentPath: "a",
            presentationState: selectionPresentationState,
            direction: .down,
            in: ["a", "b", "c"],
            path: { $0 }
        ) == "b")
        #expect(FileListRules.selectionDirection(isMovingUp: true, isMovingDown: false) == .up)
        #expect(FileListRules.selectionDirection(isMovingUp: false, isMovingDown: true) == .down)
        #expect(FileListRules.selectionDirection(isMovingUp: false, isMovingDown: false) == nil)
        var performedSelections: [String] = []
        #expect(FileListRules.performNextSelection(
            currentPath: "a",
            presentationState: selectionPresentationState,
            direction: .down,
            in: ["a", "b", "c"],
            path: { $0 },
            select: { performedSelections.append($0) }
        ))
        #expect(FileListRules.performNextSelection(
            currentPath: nil,
            presentationState: FileListRules.presentationState(
                allPaths: [],
                filterText: "",
                isHistoryMode: false,
                stagedPaths: [],
                unstagedPaths: [],
                untrackedPaths: [],
                selectedBatchPaths: []
            ),
            direction: .down,
            in: [] as [String],
            path: { $0 },
            select: { performedSelections.append($0) }
        ) == false)
        #expect(FileListRules.performMoveSelection(
            currentPath: "b",
            presentationState: selectionPresentationState,
            isMovingUp: true,
            isMovingDown: false,
            in: ["a", "b", "c"],
            path: { $0 },
            select: { performedSelections.append($0) }
        ))
        #expect(FileListRules.performMoveSelection(
            currentPath: "b",
            presentationState: selectionPresentationState,
            isMovingUp: false,
            isMovingDown: true,
            in: ["a", "b", "c"],
            path: { $0 },
            select: { performedSelections.append($0) }
        ))
        #expect(FileListRules.performMoveSelection(
            currentPath: "b",
            presentationState: selectionPresentationState,
            isMovingUp: false,
            isMovingDown: false,
            in: ["a", "b", "c"],
            path: { $0 },
            select: { performedSelections.append($0) }
        ) == false)
        #expect(performedSelections == ["b", "a", "c"])
        #expect(FileListRules.sections(
            visiblePaths: ["unstaged", "staged", "both"],
            isHistoryMode: false,
            stagedPaths: ["staged", "both"],
            unstagedPaths: ["unstaged", "both"]
        ) == [
            .init(kind: .changes, paths: ["unstaged", "both"]),
            .init(kind: .stagedChanges, paths: ["staged"]),
        ])
        #expect(FileListRules.sections(
            visiblePaths: ["a", "b"],
            isHistoryMode: true,
            stagedPaths: [],
            unstagedPaths: []
        ) == [.init(kind: .historyFiles, paths: ["a", "b"])])
        #expect(FileListRules.sections(
            visiblePaths: [],
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: []
        ).isEmpty)
        let batchState = FileListRules.batchActionState(
            allPaths: ["unstaged", "staged", "both", "untracked"],
            selectedPaths: ["unstaged", "staged", "both", "untracked"],
            stagedPaths: ["staged", "both"],
            unstagedPaths: ["unstaged", "both", "untracked"],
            untrackedPaths: ["untracked"]
        )
        #expect(batchState.selectedCount == 4)
        #expect(batchState.stageablePaths == ["unstaged", "both", "untracked"])
        #expect(batchState.unstageablePaths == ["staged", "both"])
        #expect(batchState.untrackedCount == 1)
        #expect(batchState.canStage)
        #expect(batchState.canUnstage)
        #expect(batchState.canDiscard)
        #expect(batchState.discardablePaths == ["unstaged", "staged", "both", "untracked"])
        #expect(FileListRules.stageSelectedOperationRequest(from: batchState) == .init(paths: ["unstaged", "both", "untracked"]))
        #expect(FileListRules.unstageSelectedOperationRequest(from: batchState) == .init(paths: ["staged", "both"]))
        #expect(FileListRules.discardSelectedOperationRequest(from: batchState) == .init(paths: ["unstaged", "staged", "both", "untracked"]))
        #expect(FileListRules.stageFileOperationCommand(path: "README.md") == .init(
            kind: .stage,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Stage file failed"
        ))
        #expect(FileListRules.stageSelectedOperationCommand(from: batchState) == .init(
            kind: .stage,
            request: .init(paths: ["unstaged", "both", "untracked"]),
            failureLogMessage: "Batch stage failed"
        ))
        #expect(FileListRules.unstageFileOperationCommand(path: "README.md") == .init(
            kind: .unstage,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Unstage file failed"
        ))
        #expect(FileListRules.unstageSelectedOperationCommand(from: batchState) == .init(
            kind: .unstage,
            request: .init(paths: ["staged", "both"]),
            failureLogMessage: "Batch unstage failed"
        ))
        #expect(FileListRules.discardFileOperationCommand(path: "README.md") == .init(
            kind: .discardFile,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Failed to discard file changes"
        ))
        #expect(FileListRules.discardAllOperationCommand() == .init(
            kind: .discardAll,
            failureLogMessage: "Failed to discard all changes"
        ))
        #expect(FileListRules.discardSelectedOperationCommand(from: batchState) == .init(
            kind: .discardSelected,
            request: .init(paths: ["unstaged", "staged", "both", "untracked"]),
            failureLogMessage: "Failed to batch discard"
        ))
        #expect(FileListRules.fileOperationCommand(for: .stageFile(path: "README.md")) == .init(
            kind: .stage,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Stage file failed"
        ))
        #expect(FileListRules.fileOperationCommand(for: .stageSelected(batchState)) == .init(
            kind: .stage,
            request: .init(paths: ["unstaged", "both", "untracked"]),
            failureLogMessage: "Batch stage failed"
        ))
        #expect(FileListRules.fileOperationCommand(for: .unstageFile(path: "README.md")) == .init(
            kind: .unstage,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Unstage file failed"
        ))
        #expect(FileListRules.fileOperationCommand(for: .unstageSelected(batchState)) == .init(
            kind: .unstage,
            request: .init(paths: ["staged", "both"]),
            failureLogMessage: "Batch unstage failed"
        ))
        #expect(FileListRules.fileOperationCommand(for: .discardFile(path: "README.md")) == .init(
            kind: .discardFile,
            request: .init(paths: ["README.md"]),
            failureLogMessage: "Failed to discard file changes"
        ))
        #expect(FileListRules.fileOperationCommand(for: .discardAll) == .init(
            kind: .discardAll,
            failureLogMessage: "Failed to discard all changes"
        ))
        #expect(FileListRules.fileOperationCommand(for: .discardSelected(batchState)) == .init(
            kind: .discardSelected,
            request: .init(paths: ["unstaged", "staged", "both", "untracked"]),
            failureLogMessage: "Failed to batch discard"
        ))
        var requiredProjectEvents: [String] = []
        #expect(FileListRules.performRequiredProject(
            Optional<String>.none,
            perform: { requiredProjectEvents.append($0) }
        ) == false)
        #expect(FileListRules.performRequiredProject(
            Optional("repo"),
            perform: { requiredProjectEvents.append($0) }
        ))
        #expect(requiredProjectEvents == ["repo"])
        var asyncRequiredProjectEvents: [String] = []
        #expect(await FileListRules.performRequiredProject(
            Optional<String>.none,
            perform: {
                await Task.yield()
                asyncRequiredProjectEvents.append($0)
            }
        ) == false)
        #expect(await FileListRules.performRequiredProject(
            Optional("repo"),
            perform: {
                await Task.yield()
                asyncRequiredProjectEvents.append($0)
            }
        ))
        #expect(asyncRequiredProjectEvents == ["repo"])
        var requiredProjectOperationEvents: [String] = []
        #expect(FileListRules.performRequiredProjectFileOperation(
            project: Optional<String>.none,
            command: FileListRules.stageFileOperationCommand(path: "README.md"),
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind)")
            }
        ) == false)
        #expect(FileListRules.performRequiredProjectFileOperation(
            project: Optional("repo"),
            command: FileListRules.unstageFileOperationCommand(path: "README.md"),
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind)")
            }
        ))
        #expect(FileListRules.performRequiredProjectFileOperation(
            project: Optional("repo"),
            action: .discardAll,
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind)")
            }
        ))
        #expect(FileListRules.performRequiredProjectFileOperation(
            project: Optional<String>.none,
            action: .stageSelected(batchState),
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind)")
            }
        ) == false)
        var requiredProjectOperationCommandEvents: [String] = []
        #expect(FileListRules.performRequiredProjectFileOperationCommand(
            project: Optional<String>.none,
            command: FileListRules.stageFileOperationCommand(path: "README.md"),
            perform: { projectCommand in
                requiredProjectOperationCommandEvents.append("\(projectCommand.project):\(projectCommand.command.kind)")
            }
        ) == false)
        #expect(FileListRules.performRequiredProjectFileOperationCommand(
            project: Optional("repo"),
            action: .discardFile(path: "README.md"),
            perform: { projectCommand in
                requiredProjectOperationCommandEvents.append("\(projectCommand.project):\(projectCommand.command.kind):\(projectCommand.command.request.primaryPath ?? "")")
            }
        ))
        #expect(requiredProjectOperationCommandEvents == [
            "repo:discardFile:README.md",
        ])
        struct FileOperationFixture {
            let path: String
        }
        #expect(FileListRules.performRequiredProjectStageFileOperation(
            project: Optional("repo"),
            file: FileOperationFixture(path: "stage.swift"),
            path: \.path,
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind):\(command.request.primaryPath ?? "")")
            }
        ))
        #expect(FileListRules.performRequiredProjectUnstageFileOperation(
            project: Optional("repo"),
            file: FileOperationFixture(path: "unstage.swift"),
            path: \.path,
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind):\(command.request.primaryPath ?? "")")
            }
        ))
        #expect(FileListRules.performRequiredProjectDiscardFileOperation(
            project: Optional("repo"),
            file: FileOperationFixture(path: "discard.swift"),
            path: \.path,
            perform: { command, project in
                requiredProjectOperationEvents.append("\(project):\(command.kind):\(command.request.primaryPath ?? "")")
            }
        ))
        #expect(requiredProjectOperationEvents == [
            "repo:unstage",
            "repo:discardAll",
            "repo:stage:stage.swift",
            "repo:unstage:unstage.swift",
            "repo:discardFile:discard.swift",
        ])
        let presentationState = FileListRules.presentationState(
            allPaths: ["unstaged", "staged", "both", "untracked"],
            filterText: "un",
            isHistoryMode: false,
            stagedPaths: ["staged", "both"],
            unstagedPaths: ["unstaged", "both", "untracked"],
            untrackedPaths: ["untracked"],
            selectedBatchPaths: ["unstaged", "untracked"]
        )
        #expect(presentationState.visiblePaths == ["unstaged", "untracked"])
        #expect(presentationState.sections == [.init(kind: .changes, paths: ["unstaged", "untracked"])])
        #expect(FileListRules.presentationState(
            items: [
                (path: "unstaged", index: 0),
                (path: "staged", index: 1),
                (path: "both", index: 2),
                (path: "untracked", index: 3),
            ],
            path: \.path,
            filterText: "un",
            isHistoryMode: false,
            stagedPaths: ["staged", "both"],
            unstagedPaths: ["unstaged", "both", "untracked"],
            untrackedPaths: ["untracked"],
            selectedBatchPaths: ["unstaged", "untracked"]
        ).visiblePaths == ["unstaged", "untracked"])
        #expect(FileListRules.items(
            from: ["unstaged", "staged", "untracked"],
            in: presentationState.sections[0],
            path: { $0 }
        ) == ["unstaged", "untracked"])
        #expect(FileListRules.visibleItems(
            from: ["unstaged", "staged", "untracked"],
            presentationState: presentationState,
            path: { $0 }
        ) == ["unstaged", "untracked"])
        #expect(presentationState.batchActionState.stageablePaths == ["unstaged", "untracked"])
        #expect(presentationState.batchActionState.untrackedCount == 1)
        #expect(presentationState.discardAllAlertMessage.contains("untracked"))
        #expect(presentationState.discardSelectedAlertMessage.contains("1 untracked"))
        #expect(presentationState.showsDiscardAll)
        #expect(presentationState.showsBatchActionBar)
        #expect(presentationState.canSelectAll)
        #expect(presentationState.showsEmptyState == false)
        #expect(presentationState.emptyStateIsFiltering)
        #expect(FileListRules.batchSelectionPathsAfterSelectAll(
            currentSelection: ["existing"],
            presentationState: presentationState
        ) == ["existing", "unstaged", "untracked"])
        #expect(FileListRules.discardAllPromptState(from: presentationState) == .init(showsPrompt: true))
        #expect(FileListRules.discardSelectedPromptState(from: presentationState) == .init(showsPrompt: true))
        let historyPresentationState = FileListRules.presentationState(
            allPaths: ["a"],
            filterText: "",
            isHistoryMode: true,
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        )
        #expect(FileListRules.presentationState(
            allPaths: ["a"],
            filterText: "",
            isHistoryMode: true,
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        ).showsBatchActionBar == false)
        #expect(FileListRules.presentationState(
            allPaths: ["a"],
            filterText: "missing",
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        ).canSelectAll == false)
        #expect(FileListRules.presentationState(
            allPaths: ["a"],
            filterText: "missing",
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        ).showsEmptyState)
        #expect(FileListRules.presentationState(
            allPaths: ["a"],
            filterText: " ",
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        ).emptyStateIsFiltering == false)
        #expect(FileListRules.presentationState(
            items: ["a"],
            path: { $0 },
            filterText: "",
            selectedCommit: Optional("commit"),
            stagedPaths: [],
            unstagedPaths: [],
            untrackedPaths: [],
            selectedBatchPaths: ["a"]
        ).showsBatchActionBar == false)
        #expect(FileListRules.fileRowActionState(
            path: "a",
            isHistoryMode: false,
            selectedBatchPaths: ["a"]
        ) == .init(canEditWorkingTree: true, showsStageBadge: true, isBatchSelected: true))
        #expect(FileListRules.fileRowActionState(
            path: "a",
            isHistoryMode: true,
            selectedBatchPaths: ["a"]
        ) == .init(canEditWorkingTree: false, showsStageBadge: false, isBatchSelected: true))
        #expect(FileListRules.fileRowActionState(
            path: "a",
            selectedCommit: Optional("commit"),
            selectedBatchPaths: ["a"]
        ) == .init(canEditWorkingTree: false, showsStageBadge: false, isBatchSelected: true))
        let projectURL = URL(fileURLWithPath: "/repo")
        #expect(FileListRules.fileRowPresentationState(
            path: "a",
            selectedCommit: Optional<String>.none,
            selectedBatchPaths: ["a"],
            project: Optional(projectURL),
            projectURL: { $0 }
        ) == .init(
            projectURL: projectURL,
            actionState: .init(canEditWorkingTree: true, showsStageBadge: true, isBatchSelected: true)
        ))
        #expect(FileListRules.fileRowPresentationState(
            path: "a",
            selectedCommit: Optional("commit"),
            selectedBatchPaths: [],
            project: Optional(projectURL),
            projectURL: { $0 }
        ) == .init(
            projectURL: projectURL,
            actionState: .init(canEditWorkingTree: false, showsStageBadge: false, isBatchSelected: false)
        ))
        #expect(FileListRules.fileRowPresentationState(
            path: "a",
            selectedCommit: Optional<String>.none,
            selectedBatchPaths: [],
            project: Optional<URL>.none,
            projectURL: { $0 }
        ).projectURL == nil)
        #expect(FileListRules.discardAllPromptState(from: historyPresentationState) == .init(showsPrompt: false))
        #expect(FileListRules.discardSelectedPromptState(from: historyPresentationState) == .init(showsPrompt: false))
        var showsDiscardAllPrompt = false
        FileListRules.performDiscardAllPrompt(
            presentationState: presentationState,
            setPresented: { showsDiscardAllPrompt = $0 }
        )
        #expect(showsDiscardAllPrompt)
        FileListRules.performDiscardAllPrompt(
            presentationState: historyPresentationState,
            setPresented: { showsDiscardAllPrompt = $0 }
        )
        #expect(showsDiscardAllPrompt == false)
        var showsDiscardSelectedPrompt = false
        FileListRules.performDiscardSelectedPrompt(
            presentationState: presentationState,
            setPresented: { showsDiscardSelectedPrompt = $0 }
        )
        #expect(showsDiscardSelectedPrompt)
        FileListRules.performDiscardSelectedPrompt(
            presentationState: historyPresentationState,
            setPresented: { showsDiscardSelectedPrompt = $0 }
        )
        #expect(showsDiscardSelectedPrompt == false)
        #expect(FileListRules.discardFilePromptState(canDiscard: true) == .init(showsPrompt: true))
        #expect(FileListRules.discardFilePromptState(canDiscard: false) == .init(showsPrompt: false))
        #expect(FileListRules.discardSelectionPromptState(
            hasSelection: true,
            isHistoryMode: false
        ) == .init(showsPrompt: true))
        #expect(FileListRules.discardSelectionPromptState(
            hasSelection: true,
            isHistoryMode: true
        ) == .init(showsPrompt: false))
        #expect(FileListRules.discardSelectionPromptState(
            hasSelection: false,
            isHistoryMode: false
        ) == .init(showsPrompt: false))
        var discardSelectionPrompts: [String] = []
        #expect(FileListRules.performDiscardSelectionPrompt(
            selection: Optional("README.md"),
            isHistoryMode: false,
            prompt: { discardSelectionPrompts.append($0) }
        ))
        #expect(FileListRules.performDiscardSelectionPrompt(
            selection: Optional("README.md"),
            isHistoryMode: true,
            prompt: { discardSelectionPrompts.append($0) }
        ) == false)
        #expect(FileListRules.performDiscardSelectionPrompt(
            selection: Optional<String>.none,
            isHistoryMode: false,
            prompt: { discardSelectionPrompts.append($0) }
        ) == false)
        #expect(discardSelectionPrompts == ["README.md"])
        var selectedFile: String?
        var syncedFile: String?
        FileListRules.performFileSelection(
            Optional("Sources/App.swift"),
            setSelection: { selectedFile = $0 },
            syncSelection: { syncedFile = $0 }
        )
        #expect(selectedFile == "Sources/App.swift")
        #expect(syncedFile == "Sources/App.swift")
        FileListRules.performFileSelection(
            Optional<String>.none,
            setSelection: { selectedFile = $0 },
            syncSelection: { syncedFile = $0 }
        )
        #expect(selectedFile == nil)
        #expect(syncedFile == nil)
        FileListRules.performSelectionChange(
            Optional("Sources/App.swift"),
            syncSelection: { syncedFile = $0 }
        )
        #expect(syncedFile == "Sources/App.swift")
        FileListRules.performSelectionChange(
            Optional<String>.none,
            syncSelection: { syncedFile = $0 }
        )
        #expect(syncedFile == nil)
        var fileToDiscard = ""
        var showsDiscardPrompt = false
        FileListRules.performDiscardFilePrompt(
            "README.md",
            setFileToDiscard: { fileToDiscard = $0 },
            setPresented: { showsDiscardPrompt = $0 }
        )
        #expect(fileToDiscard == "README.md")
        #expect(showsDiscardPrompt)
        FileListRules.performDiscardFilePromptCancellation(
            setFileToDiscard: { fileToDiscard = $0 ?? "" }
        )
        #expect(fileToDiscard.isEmpty)
        var discardedFiles: [String] = []
        #expect(FileListRules.performConfirmedDiscardFile(
            Optional("README.md"),
            discard: { discardedFiles.append($0) },
            clearFileToDiscard: { fileToDiscard = $0 ?? "" }
        ))
        #expect(discardedFiles == ["README.md"])
        #expect(fileToDiscard.isEmpty)
        fileToDiscard = "stale"
        #expect(FileListRules.performConfirmedDiscardFile(
            Optional<String>.none,
            discard: { discardedFiles.append($0) },
            clearFileToDiscard: { fileToDiscard = $0 ?? "" }
        ) == false)
        #expect(discardedFiles == ["README.md"])
        #expect(fileToDiscard.isEmpty)
        #expect(FileListRules.retainedBatchSelection(
            afterRemoving: ["unstaged", "both"],
            from: ["unstaged", "staged", "both"]
        ) == ["staged"])
        #expect(FileListRules.stagedPaths(indexStatuses: [
            (path: "a", indexStatus: "M"),
            (path: "b", indexStatus: "?"),
            (path: "c", indexStatus: " ")
        ]) == ["a"])
        #expect(FileListRules.unstagedPaths(statuses: [
            (path: "a", indexStatus: " ", workTreeStatus: "M"),
            (path: "b", indexStatus: "?", workTreeStatus: " "),
            (path: "c", indexStatus: "M", workTreeStatus: " ")
        ]) == ["a", "b"])
        #expect(FileListRules.untrackedPaths(indexStatuses: [
            (path: "a", indexStatus: "?"),
            (path: "b", indexStatus: "M")
        ]) == ["a"])
    }

    @Test("git detail layout metrics match legacy app layout")
    func gitDetailLayoutMetrics() {
        #expect(GitDetailLayoutMetrics.headerHorizontalPadding == 8)
        #expect(GitDetailLayoutMetrics.headerVerticalPadding == 8)
        #expect(GitDetailLayoutMetrics.fileListIdealWidth == 200)
        #expect(GitDetailLayoutMetrics.fileListMinWidth == 200)
        #expect(GitDetailLayoutMetrics.fileListMaxWidth == 420)
    }

    @Test("git detail presentation visibility matches project state")
    func gitDetailPresentationVisibility() {
        #expect(GitDetailPresentationRules.rootContentMode(
            hasProject: false,
            isGitProject: false
        ) == .hidden)
        #expect(GitDetailPresentationRules.rootContentMode(
            hasProject: true,
            isGitProject: false
        ) == .notGitProject)
        #expect(GitDetailPresentationRules.rootContentMode(
            hasProject: true,
            isGitProject: true
        ) == .gitProject)
        #expect(GitDetailPresentationRules.gitProjectState(
            hasProject: false,
            projectIsGitRepository: true
        ) == false)
        #expect(GitDetailPresentationRules.gitProjectState(
            hasProject: true,
            projectIsGitRepository: false
        ) == false)
        #expect(GitDetailPresentationRules.gitProjectState(
            hasProject: true,
            projectIsGitRepository: true
        ))
        #expect(GitDetailPresentationRules.gitProjectState(
            project: "repo" as String?,
            projectIsGitRepository: true
        ))
        #expect(GitDetailPresentationRules.gitProjectState(
            project: nil as String?,
            projectIsGitRepository: true
        ) == false)
        var appliedGitProjectState: Bool?
        GitDetailPresentationRules.performGitProjectState(
            project: "repo" as String?,
            projectIsGitRepository: true,
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == true)
        GitDetailPresentationRules.performGitProjectState(
            project: nil as String?,
            projectIsGitRepository: true,
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == false)
        var gitProjectStateLoaderCalls: [String] = []
        GitDetailPresentationRules.performGitProjectState(
            project: "repo" as String?,
            projectIsGitRepository: { project in
                gitProjectStateLoaderCalls.append(project)
                return true
            },
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == true)
        GitDetailPresentationRules.performGitProjectState(
            project: nil as String?,
            projectIsGitRepository: { project in
                gitProjectStateLoaderCalls.append(project)
                return true
            },
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == false)
        #expect(gitProjectStateLoaderCalls == ["repo"])
        GitDetailPresentationRules.performGitProjectStateCommand(
            project: "repo" as String?,
            projectIsGitRepository: { request in
                gitProjectStateLoaderCalls.append("command:\(request.project)")
                return true
            },
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == true)
        GitDetailPresentationRules.performGitProjectStateCommand(
            project: nil as String?,
            projectIsGitRepository: { request in
                gitProjectStateLoaderCalls.append("command:\(request.project)")
                return true
            },
            setIsGitProject: { appliedGitProjectState = $0 }
        )
        #expect(appliedGitProjectState == false)
        #expect(gitProjectStateLoaderCalls == ["repo", "command:repo"])
        var gitDetailEventUpdates = 0
        GitDetailPresentationRules.performAppear {
            gitDetailEventUpdates += 1
        }
        GitDetailPresentationRules.performProjectChange {
            gitDetailEventUpdates += 1
        }
        GitDetailPresentationRules.performApplicationWillBecomeActive {
            gitDetailEventUpdates += 1
        }
        #expect(gitDetailEventUpdates == 3)
        #expect(GitDetailPresentationRules.headerContentMode(
            hasSelectedCommit: true,
            isClean: true
        ) == .commitInfo)
        #expect(GitDetailPresentationRules.headerContentMode(
            hasSelectedCommit: false,
            isClean: false
        ) == .commitForm)
        #expect(GitDetailPresentationRules.headerContentMode(
            hasSelectedCommit: false,
            isClean: true
        ) == .none)
        #expect(GitDetailPresentationRules.contentVisibility(
            hasSelectedCommit: false,
            isClean: true
        ) == .init(showsHeader: false, showsFileSplit: false))
        #expect(GitDetailPresentationRules.contentVisibility(
            hasSelectedCommit: true,
            isClean: true
        ) == .init(showsHeader: true, showsFileSplit: true))
        #expect(GitDetailPresentationRules.contentVisibility(
            hasSelectedCommit: false,
            isClean: false
        ) == .init(showsHeader: true, showsFileSplit: true))
        #expect(GitDetailPresentationRules.presentationState(
            hasProject: true,
            isGitProject: true,
            hasSelectedCommit: true,
            isClean: true
        ) == .init(
            rootContentMode: .gitProject,
            headerContentMode: .commitInfo,
            contentVisibility: .init(showsHeader: true, showsFileSplit: true)
        ))
        #expect(GitDetailPresentationRules.presentationState(
            hasProject: true,
            isGitProject: false,
            hasSelectedCommit: false,
            isClean: true
        ) == .init(
            rootContentMode: .notGitProject,
            headerContentMode: .none,
            contentVisibility: .init(showsHeader: false, showsFileSplit: false)
        ))
        #expect(GitDetailPresentationRules.presentationState(
            project: "repo" as String?,
            isGitProject: true,
            selectedCommit: "commit" as String?,
            isClean: true
        ) == .init(
            rootContentMode: .gitProject,
            headerContentMode: .commitInfo,
            contentVisibility: .init(showsHeader: true, showsFileSplit: true)
        ))
        struct CommitInfoFixture {
            let message: String
            let body: String
            let author: String
            let date: String
            let hash: String
        }
        #expect(GitDetailPresentationRules.commitInfoPresentationState(
            selectedCommit: Optional<CommitInfoFixture>.none,
            message: \.message,
            bodyText: \.body,
            author: \.author,
            date: \.date,
            hash: \.hash
        ) == nil)
        #expect(GitDetailPresentationRules.commitInfoPresentationState(
            selectedCommit: CommitInfoFixture(
                message: "Subject",
                body: "Body",
                author: "Ada",
                date: "Today",
                hash: "abc123"
            ),
            message: \.message,
            bodyText: \.body,
            author: \.author,
            date: \.date,
            hash: \.hash
        ) == .init(
            message: "Subject",
            bodyText: "Body",
            author: "Ada",
            date: "Today",
            hash: "abc123"
        ))
    }

    @Test("file detail host view is constructible from app adapters")
    @MainActor
    func fileDetailHostViewConstructsFromAdapters() {
        struct FileFixture: Equatable {
            let file: String
            let isImage: Bool
            let isBinary: Bool
            let changeType: String
            let diff: String
        }
        struct CommitFixture {
            let hash: String
            let parentHashes: [String]
        }

        let file = FileFixture(
            file: "Sources/App.swift",
            isImage: false,
            isBinary: false,
            changeType: "M",
            diff: "-old\n+new"
        )
        let view = FileDetailHostView<String, FileFixture, CommitFixture, CommitFixture, EmptyView>(
            project: "repo",
            file: file,
            selectedCommit: CommitFixture(hash: "abc", parentHashes: ["parent"]),
            filePath: \.file,
            isImage: \.isImage,
            isBinary: \.isBinary,
            changeType: \.changeType,
            existingPatch: \.diff,
            selectedCommitHash: \.hash,
            loadCurrentCommitData: { _, _, _ in Data() },
            loadCurrentWorktreeData: { _, _ in Data() },
            loadCommits: { _ in [] },
            loadedCommitHash: \.hash,
            loadedParentHashes: \.parentHashes,
            loadHeadHash: { _ in nil },
            loadPreviousCommitData: { _, _, _ in Data() },
            loadCommitContent: { _, _, _ in (before: "old", after: "new") },
            loadWorktreeContent: { _, _ in (before: "old", after: "new") },
            loadCommitDiff: { _, _, _ in "-old\n+new" },
            loadWorktreeDiff: { _, _ in "-old\n+new" },
            missingProjectError: { GitDetailError.invalidProject },
            copyText: { _ in },
            handleEvent: { _ in },
            renderContent: { _ in EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("file list host view is constructible from app adapters")
    @MainActor
    func fileListHostViewConstructsFromAdapters() {
        struct FileFixture: Hashable {
            let file: String
            let changeType: String
        }
        struct CommitFixture {
            let hash: String
        }
        struct StatusFixture {
            let path: String
            let indexStatus: String
            let workTreeStatus: String
        }

        let view = FileListHostView<String, CommitFixture, FileFixture, StatusFixture>(
            project: "repo",
            selectedCommit: nil,
            projectURL: { URL(fileURLWithPath: "/tmp/\($0)") },
            projectPath: { $0 },
            commitHash: \.hash,
            filePath: \.file,
            fileChangeType: \.changeType,
            statusPath: \.path,
            statusIndexStatus: { $0.indexStatus },
            statusWorkTreeStatus: { $0.workTreeStatus },
            scrollTarget: nil,
            syncSelection: { _ in },
            loadCommitFiles: { _, _ in [FileFixture(file: "Sources/App.swift", changeType: "M")] },
            loadWorktreeFiles: { _ in [FileFixture(file: "Sources/App.swift", changeType: "M")] },
            loadStatusEntries: { _ in [StatusFixture(path: "Sources/App.swift", indexStatus: "M", workTreeStatus: " ")] },
            addFiles: { _, _ in },
            unstageFiles: { _, _ in },
            discardFileChanges: { _, _ in },
            discardAllChanges: { _ in },
            mapRefreshError: { $0.localizedDescription }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }

    @Test("git detail host view is constructible from app adapters")
    @MainActor
    func gitDetailHostViewConstructsFromAdapters() {
        struct CommitFixture {
            let message: String
            let body: String
            let author: String
            let date: Date
            let hash: String
        }

        let view = GitDetailHostView<String, CommitFixture, EmptyView, EmptyView, EmptyView, EmptyView, EmptyView, EmptyView>(
            project: "repo",
            selectedCommit: CommitFixture(
                message: "Subject",
                body: "Body",
                author: "Ada",
                date: Date(timeIntervalSince1970: 0),
                hash: "abc123"
            ),
            isClean: false,
            projectIsGitRepository: { _ in true },
            commitMessage: \.message,
            commitBodyText: \.body,
            commitAuthor: \.author,
            commitDate: \.date,
            commitHash: \.hash,
            commitInfoContent: { _ in EmptyView() },
            fileListContent: { EmptyView() },
            fileDetailContent: { EmptyView() },
            emptyContent: { EmptyView() },
            notGitContent: { EmptyView() },
            commitFormContent: { EmptyView() }
        )

        #expect(Mirror(reflecting: view).children.isEmpty == false)
    }
}
