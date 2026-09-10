import Foundation
import LumiUI
import ProviderActivityHeatmap
import ProviderContentView
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// Compact GitHub-style activity grid shown beside the clean-worktree view.
struct WorktreeCleanActivityHeatmapView: View {
    @ObservedObject var viewModel: WorktreeCleanActivityHeatmapViewModel
    @LumiTheme private var theme

    private let calendar: Calendar
    private let minimumWeekCount = 26
    private let maximumWeekCount = 52
    private let minimumSummaryWidth: CGFloat = 224
    private let summaryColumnSpacing: CGFloat = 20
    private let summaryDividerWidth: CGFloat = 1
    private let cellSpacing: CGFloat = 3
    private let minimumCellSize: CGFloat = 10
    private let heatmapContentMinHeight: CGFloat = 196

    init(viewModel: WorktreeCleanActivityHeatmapViewModel, calendar: Calendar = .current) {
        self.viewModel = viewModel
        var calendar = calendar
        calendar.firstWeekday = 1
        self.calendar = calendar
    }

    var body: some View {
        Group {
            if viewModel.isVisible {
                if let snapshot = viewModel.snapshot {
                    heatmap(snapshot: snapshot)
                } else {
                    loadingView
                }
            } else {
                EmptyView()
            }
        }
    }

    private var loadingView: some View {
        activityCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(loc("Commit Activity"))
                    .font(.headline)

                VStack(spacing: 6) {
                    ContentLoadingIndicator(loc("Loading commit activity..."), controlSize: .small)
                        .tint(theme.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc("Analyzing recent Git history..."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 105)
            }
        }
    }

    private func heatmap(snapshot: ActivityHeatmapSnapshot) -> some View {
        activityCard {
            GeometryReader { proxy in
                let layout = layout(for: proxy.size.width)
                let summaryWidth = layout.showsSummary
                    ? min(240, max(minimumSummaryWidth, proxy.size.width * 0.28))
                    : 0
                let gridWidth = layout.showsSummary
                    ? proxy.size.width
                        - summaryWidth
                        - summaryColumnSpacing * 2
                        - summaryDividerWidth
                    : proxy.size.width
                let weekCount = weekCount(for: gridWidth)
                let cellSize = cellSize(for: gridWidth, weekCount: weekCount)
                let maximumCommitCount = visibleDays(
                    in: snapshot,
                    weekCount: weekCount
                ).map(\.commitCount).max() ?? 0

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc("Commit Activity"))
                                .font(.headline)
                            Text(summary(for: snapshot, weekCount: weekCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        if viewModel.isLoading {
                            ContentLoadingIndicator(loc("Updating commit activity..."), controlSize: .small)
                                .tint(theme.primary)
                        }
                    }

                    HStack(alignment: .top, spacing: summaryColumnSpacing) {
                        heatmapGrid(
                            weekCount: weekCount,
                            cellSize: cellSize,
                            maximumCommitCount: maximumCommitCount
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if layout.showsSummary {
                            Divider()
                                .frame(height: 7 * cellSize + 6 * cellSpacing)
                            activitySummary(snapshot: snapshot, weekCount: weekCount)
                                .frame(width: summaryWidth, alignment: .topLeading)
                                .clipped()
                        }
                    }

                    legend(cellSize: cellSize)
                }
            }
            // GeometryReader does not grow to fit its child in a vertical
            // ScrollView. Reserve enough height for the largest cell size,
            // otherwise the legend can render outside the card background.
            .frame(minHeight: heatmapContentMinHeight)
        }
    }

    private func heatmapGrid(
        weekCount: Int,
        cellSize: CGFloat,
        maximumCommitCount: Int?
    ) -> some View {
        HStack(alignment: .top, spacing: 5) {
            weekdayLabels(cellSize: cellSize)
            LazyHStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(weeks(weekCount: weekCount).enumerated()), id: \.offset) { _, week in
                    VStack(spacing: cellSpacing) {
                        ForEach(week) { cell in
                            dayCell(
                                cell,
                                size: cellSize,
                                maximumCommitCount: maximumCommitCount
                            )
                        }
                    }
                }
            }
        }
    }

    private func legend(cellSize: CGFloat) -> some View {
        HStack(spacing: 4) {
            Text(loc("Less"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text(loc("More"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func activitySummary(
        snapshot: ActivityHeatmapSnapshot,
        weekCount: Int
    ) -> some View {
        let metrics = metrics(for: snapshot, weekCount: weekCount)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(metrics.totalCommits)")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Text(loc("Commits"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 12
            ) {
                metric(label: loc("Active days"), value: "\(metrics.activeDays)")
                metric(label: loc("Busiest day"), value: metrics.busiestDay)
                metric(label: loc("Longest streak"), value: "\(metrics.longestStreak)")
                metric(label: loc("Avg. per week"), value: metrics.averagePerWeek(weekCount: weekCount))
            }
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.callout.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activityCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func weekdayLabels(cellSize: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Color.clear.frame(height: cellSize)
            Text(loc("Mon")).font(.caption2).foregroundStyle(.secondary).frame(height: cellSize)
            Color.clear.frame(height: cellSize)
            Text(loc("Wed")).font(.caption2).foregroundStyle(.secondary).frame(height: cellSize)
            Color.clear.frame(height: cellSize)
            Text(loc("Fri")).font(.caption2).foregroundStyle(.secondary).frame(height: cellSize)
            Color.clear.frame(height: cellSize)
        }
        .frame(width: 23)
    }

    private func weeks(weekCount: Int) -> [[HeatmapCell]] {
        let referenceDate = calendar.startOfDay(for: viewModel.snapshot?.generatedAt ?? Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
        let start = calendar.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: weekStart) ?? weekStart
        let counts = (viewModel.snapshot?.days ?? []).reduce(into: [Date: ActivityHeatmapDay]()) {
            $0[calendar.startOfDay(for: $1.date)] = $1
        }

        return (0..<weekCount).map { weekIndex in
            (0..<7).compactMap { weekday in
                guard let date = calendar.date(
                    byAdding: .day,
                    value: weekIndex * 7 + weekday,
                    to: start
                ) else { return nil }
                return HeatmapCell(date: date, activity: counts[date])
            }
        }
    }

    private func dayCell(
        _ cell: HeatmapCell,
        size: CGFloat,
        maximumCommitCount: Int? = nil
    ) -> some View {
        let level = cell.activity.map {
            viewModel.level(for: $0, maximum: maximumCommitCount)
        } ?? 0
        return RoundedRectangle(cornerRadius: 2)
            .fill(color(for: level))
            .frame(width: size, height: size)
            .accessibilityLabel(accessibilityLabel(for: cell))
            .help(accessibilityLabel(for: cell))
    }

    private func color(for level: Int) -> Color {
        let accent = theme.primary
        switch level {
        case 1: return accent.opacity(0.28)
        case 2: return accent.opacity(0.48)
        case 3: return accent.opacity(0.70)
        case 4: return accent.opacity(0.92)
        default: return accent.opacity(0.10)
        }
    }

    private func summary(for snapshot: ActivityHeatmapSnapshot, weekCount: Int) -> String {
        let totalCommits = metrics(for: snapshot, weekCount: weekCount).totalCommits
        return String(
            format: loc("%lld commits in the last %lld months"),
            totalCommits,
            periodMonths(for: weekCount)
        )
    }

    private func layout(for width: CGFloat) -> ActivityLayout {
        ActivityLayout(showsSummary: width >= 680)
    }

    private func weekCount(for width: CGFloat) -> Int {
        let availableGridWidth = max(0, width - 23 - 5)
        let possibleWeeks = Int(
            floor((availableGridWidth + cellSpacing) / (minimumCellSize + cellSpacing))
        )

        if possibleWeeks >= maximumWeekCount { return maximumWeekCount }
        if possibleWeeks >= 39 { return 39 }
        return minimumWeekCount
    }

    private func cellSize(for width: CGFloat, weekCount: Int) -> CGFloat {
        let availableGridWidth = max(0, width - 23 - 5)
        let size = (availableGridWidth - CGFloat(weekCount - 1) * cellSpacing)
            / CGFloat(weekCount)
        return min(13, max(minimumCellSize, size))
    }

    private func periodMonths(for weekCount: Int) -> Int {
        switch weekCount {
        case 52: return 12
        case 39: return 9
        default: return 6
        }
    }

    private func visibleDays(
        in snapshot: ActivityHeatmapSnapshot,
        weekCount: Int
    ) -> [ActivityHeatmapDay] {
        let referenceDate = calendar.startOfDay(for: snapshot.generatedAt)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
        let start = calendar.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: weekStart) ?? weekStart
        let end = calendar.date(byAdding: .day, value: weekCount * 7 - 1, to: start) ?? start
        return snapshot.days.filter { $0.date >= start && $0.date <= end }
    }

    private func metrics(
        for snapshot: ActivityHeatmapSnapshot,
        weekCount: Int
    ) -> ActivityMetrics {
        let activeDays = visibleDays(in: snapshot, weekCount: weekCount)
            .filter { $0.commitCount > 0 }
        let busiest = activeDays.max {
            if $0.commitCount == $1.commitCount {
                return $0.date < $1.date
            }
            return $0.commitCount < $1.commitCount
        }

        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        for day in activeDays.sorted(by: { $0.date < $1.date }) {
            if let previousDate,
               calendar.dateComponents([.day], from: previousDate, to: day.date).day == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            longestStreak = max(longestStreak, currentStreak)
            previousDate = day.date
        }

        return ActivityMetrics(
            activeDays: activeDays.count,
            busiestDay: busiest.map {
                "\($0.commitCount) · \($0.date.formatted(date: .abbreviated, time: .omitted))"
            } ?? "—",
            longestStreak: longestStreak,
            totalCommits: activeDays.reduce(0) { $0 + $1.commitCount }
        )
    }

    private func accessibilityLabel(for cell: HeatmapCell) -> String {
        let count = cell.activity?.commitCount ?? 0
        let date = cell.date.formatted(date: .abbreviated, time: .omitted)
        return String(format: loc("%@, %lld commits"), date, count)
    }

    private struct HeatmapCell: Identifiable {
        let date: Date
        let activity: ActivityHeatmapDay?
        var id: Date { date }
    }

    private struct ActivityLayout {
        let showsSummary: Bool
    }

    private struct ActivityMetrics {
        let activeDays: Int
        let busiestDay: String
        let longestStreak: Int
        let totalCommits: Int

        func averagePerWeek(weekCount: Int) -> String {
            let average = Double(totalCommits) / Double(max(1, weekCount))
            return String(format: "%.1f", average)
        }
    }
}
