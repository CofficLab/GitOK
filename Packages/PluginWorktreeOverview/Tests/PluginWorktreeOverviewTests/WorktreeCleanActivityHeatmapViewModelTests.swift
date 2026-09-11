import Foundation
import ProviderActivityHeatmap
import Testing
@testable import PluginWorktreeOverview

@MainActor
@Suite("WorktreeCleanActivityHeatmapViewModel")
struct WorktreeCleanActivityHeatmapViewModelTests {
    @Test("maps activity counts to five stable levels")
    func mapsActivityCountsToLevels() {
        let date = Date(timeIntervalSince1970: 100)
        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [
                ActivityHeatmapDay(date: date, commitCount: 0),
                ActivityHeatmapDay(date: date.addingTimeInterval(86_400), commitCount: 1),
                ActivityHeatmapDay(date: date.addingTimeInterval(172_800), commitCount: 2),
                ActivityHeatmapDay(date: date.addingTimeInterval(259_200), commitCount: 3),
                ActivityHeatmapDay(date: date.addingTimeInterval(345_600), commitCount: 4),
            ]
        )
        let provider = DefaultActivityHeatmapProvider(snapshot: snapshot)
        let capability = TestCapability(provider: provider)
        let viewModel = WorktreeCleanActivityHeatmapViewModel()
        viewModel.handleContextChanged(
            projectURL: URL(fileURLWithPath: "/tmp/repo"),
            hasSelectedCommit: false,
            capability: capability
        )

        #expect(viewModel.level(for: snapshot.days[0]) == 0)
        #expect(viewModel.level(for: snapshot.days[1]) == 1)
        #expect(viewModel.level(for: snapshot.days[2]) == 2)
        #expect(viewModel.level(for: snapshot.days[3]) == 3)
        #expect(viewModel.level(for: snapshot.days[4]) == 4)
        #expect(viewModel.isVisible)
        #expect(!viewModel.isLoading)
    }

    @Test("hides activity while a commit is selected")
    func hidesActivityWhileCommitIsSelected() {
        let provider = DefaultActivityHeatmapProvider()
        let capability = TestCapability(provider: provider)
        let viewModel = WorktreeCleanActivityHeatmapViewModel()
        viewModel.handleContextChanged(
            projectURL: URL(fileURLWithPath: "/tmp/repo"),
            hasSelectedCommit: true,
            capability: capability
        )

        #expect(!viewModel.isVisible)
    }

    @Test("shows the activity card while data is loading")
    func showsActivityWhileLoading() {
        let provider = DefaultActivityHeatmapProvider()
        provider.setLoading(true)
        let capability = TestCapability(provider: provider)
        let viewModel = WorktreeCleanActivityHeatmapViewModel()

        viewModel.handleContextChanged(
            projectURL: URL(fileURLWithPath: "/tmp/repo"),
            hasSelectedCommit: false,
            capability: capability
        )

        #expect(viewModel.isLoading)
        #expect(viewModel.isVisible)
    }

    @MainActor
    private final class TestCapability: WorktreeCleanActivityHeatmapCapability {
        let provider: DefaultActivityHeatmapProvider

        init(provider: DefaultActivityHeatmapProvider) {
            self.provider = provider
        }

        var currentSnapshot: ActivityHeatmapSnapshot? { provider.currentSnapshot }
        var isLoading: Bool { provider.isLoading }

        func addObserver(
            _ callback: @escaping (ActivityHeatmapEvent) -> Void
        ) -> any ActivityHeatmapObserverHandle {
            provider.addObserver(callback)
        }
    }
}
