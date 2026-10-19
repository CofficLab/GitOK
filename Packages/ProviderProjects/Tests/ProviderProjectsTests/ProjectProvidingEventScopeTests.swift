import Foundation
import Testing

@testable import ProviderProjects

@Suite("ProjectProvidingEvent 事件范围")
@MainActor
struct ProjectProvidingEventScopeTests {

    @Test(
        "仓库级事件：切换项目与仓库数据变化",
        arguments: [
            ProjectProvidingEvent.selectionChanged(projectID: nil),
            .dataChanged
        ]
    )
    func repositoryScopedEvents(event: ProjectProvidingEvent) {
        #expect(event.isRepositoryScoped)
        #expect(event.isProjectListScoped == false)
    }

    @Test(
        "既非仓库级也非项目列表级的事件属于会话级选择",
        arguments: [
            ProjectProvidingEvent.commitSelectionChanged,
            .currentFileChanged
        ]
    )
    func sessionSelectionEvents(event: ProjectProvidingEvent) {
        #expect(event.isRepositoryScoped == false)
        #expect(event.isProjectListScoped == false)
    }

    @Test("项目列表变化事件")
    func projectListScopedEvent() {
        let event = ProjectProvidingEvent.projectsChanged

        #expect(event.isProjectListScoped)
        #expect(event.isRepositoryScoped == false)
    }

    @Test("每个事件恰好归入仓库级、项目列表级或会话级之一")
    func scopesAreExhaustiveAndMutuallyExclusive() {
        let events: [ProjectProvidingEvent] = [
            .projectsChanged,
            .selectionChanged(projectID: nil),
            .dataChanged,
            .commitSelectionChanged,
            .currentFileChanged
        ]

        for event in events {
            let scopeCount = [
                event.isRepositoryScoped,
                event.isProjectListScoped
            ].filter { $0 }.count

            // 不能同时属于两个范围
            #expect(
                scopeCount <= 1,
                "事件同时属于多个范围：\(event)"
            )
            // 仓库级与项目列表级合计应覆盖除会话级选择外的全部事件
            if event.isRepositoryScoped || event.isProjectListScoped {
                #expect(scopeCount == 1, "范围判定不一致：\(event)")
            }
        }

        // 三类事件的分布：仓库级 2 个、项目列表级 1 个、会话级 2 个
        #expect(events.filter(\.isRepositoryScoped).count == 2)
        #expect(events.filter(\.isProjectListScoped).count == 1)
        let sessionScoped = events.filter {
            !$0.isRepositoryScoped && !$0.isProjectListScoped
        }
        #expect(sessionScoped.count == 2)
    }

    @Test("会话级选择变化不会触发仓库级刷新")
    func sessionSelectionDoesNotTriggerRepositoryReload() {
        // 这是本次扩展要解决的核心问题：切换 commit / 文件不应让
        // 仓库级 tile（分支、stash、远程等）重新拉取 git 数据。
        #expect(ProjectProvidingEvent.commitSelectionChanged.isRepositoryScoped == false)
        #expect(ProjectProvidingEvent.currentFileChanged.isRepositoryScoped == false)
    }
}
