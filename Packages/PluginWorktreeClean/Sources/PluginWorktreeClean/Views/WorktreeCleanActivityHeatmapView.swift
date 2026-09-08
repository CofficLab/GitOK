import Foundation
import LumiUI
import ProviderActivityHeatmap
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// Compact GitHub-style activity grid shown beside the clean-worktree view.
struct WorktreeCleanActivityHeatmapView: View {
    @ObservedObject var viewModel: WorktreeCleanActivityHeatmapViewModel
    @LumiTheme private var theme

    private let calendar: Calendar
    private let weekCount = 26

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

                HStack(alignment: .top, spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc("Loading commit activity..."))
                            .font(.body)
                        Text(loc("Analyzing recent Git history..."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
            }
        }
    }

    private func heatmap(snapshot: ActivityHeatmapSnapshot) -> some View {
        activityCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loc("Commit Activity"))
                            .font(.headline)
                        Text(summary(for: snapshot))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.green)
                            .help(loc("Updating commit activity..."))
                    }
                }

                HStack(alignment: .top, spacing: 5) {
                    weekdayLabels
                    LazyHStack(alignment: .top, spacing: 3) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 3) {
                                ForEach(week) { cell in
                                    dayCell(cell)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 4) {
                    Text(loc("Less"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: level))
                            .frame(width: 10, height: 10)
                    }
                    Text(loc("More"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        .padding(.trailing, 20)
        .padding(.vertical, 16)
        .frame(minWidth: 300, idealWidth: 360, maxWidth: 420, alignment: .topLeading)
    }

    private var weekdayLabels: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Color.clear.frame(height: 10)
            Text(loc("Mon")).font(.caption2).foregroundStyle(.secondary).frame(height: 10)
            Color.clear.frame(height: 10)
            Text(loc("Wed")).font(.caption2).foregroundStyle(.secondary).frame(height: 10)
            Color.clear.frame(height: 10)
            Text(loc("Fri")).font(.caption2).foregroundStyle(.secondary).frame(height: 10)
            Color.clear.frame(height: 10)
        }
        .frame(width: 23)
    }

    private var weeks: [[HeatmapCell]] {
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

    private func dayCell(_ cell: HeatmapCell) -> some View {
        let level = cell.activity.map(viewModel.level(for:)) ?? 0
        return RoundedRectangle(cornerRadius: 2)
            .fill(color(for: level))
            .frame(width: 10, height: 10)
            .accessibilityLabel(accessibilityLabel(for: cell))
            .help(accessibilityLabel(for: cell))
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 1: return .green.opacity(0.28)
        case 2: return .green.opacity(0.48)
        case 3: return .green.opacity(0.70)
        case 4: return .green.opacity(0.92)
        default: return .green.opacity(0.10)
        }
    }

    private func summary(for snapshot: ActivityHeatmapSnapshot) -> String {
        String(format: loc("%lld commits in the last six months"), snapshot.totalCommitCount)
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
}
