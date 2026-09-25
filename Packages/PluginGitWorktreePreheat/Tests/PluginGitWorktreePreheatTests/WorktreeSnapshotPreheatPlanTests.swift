import Foundation
import ProviderProjects
import Testing
@testable import PluginGitWorktreePreheat

@Suite("WorktreeSnapshotPreheatPlan")
struct WorktreeSnapshotPreheatPlanTests {
    @Test("当前项目优先且重复路径只预热一次")
    func preferredProjectFirstAndPathsAreUnique() {
        let first = Project(url: URL(fileURLWithPath: "/tmp/gitok-project-a"))
        let second = Project(url: URL(fileURLWithPath: "/tmp/gitok-project-b"))
        let duplicate = Project(url: URL(fileURLWithPath: "/tmp/gitok-project-b/../gitok-project-b"))

        let urls = WorktreeSnapshotPreheatPlan.orderedURLs(
            projects: [first, second, duplicate],
            preferredURL: second.url
        )

        #expect(urls == [second.url.standardizedFileURL, first.url.standardizedFileURL])
    }

    @Test("没有当前项目时保留项目列表顺序")
    func keepsProjectOrderWithoutPreferredProject() {
        let projects = [
            Project(url: URL(fileURLWithPath: "/tmp/gitok-project-a")),
            Project(url: URL(fileURLWithPath: "/tmp/gitok-project-b")),
        ]

        #expect(WorktreeSnapshotPreheatPlan.orderedURLs(projects: projects, preferredURL: nil)
            == projects.map(\.url))
    }
}
