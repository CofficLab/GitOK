import LumiUI
import ProviderCloneRepository
import ProviderProjects
import SwiftUI

private func cloneFailureLocalized(_ key: String) -> String {
    pluginLocalization.string(key)
}

/// 当前项目的 clone 任务失败或被取消时显示的唯一工作区内容。
@MainActor
struct CloneFailedView: View {
    let project: Project
    let cloneRepository: any CloneRepositoryProviding

    @StateObject private var observation: CloneFailureObservation
    @State private var retryError: String?
    @LumiTheme private var theme

    init(project: Project, cloneRepository: any CloneRepositoryProviding) {
        self.project = project
        self.cloneRepository = cloneRepository
        _observation = StateObject(
            wrappedValue: CloneFailureObservation(cloneRepository: cloneRepository)
        )
    }

    private var task: CloneTask? {
        _ = observation.revision
        return cloneRepository.task(for: project.url)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if let task {
                detail(task)
                    .frame(maxWidth: 620, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
            } else {
                AppEmptyState(
                    icon: "exclamationmark.triangle",
                    title: cloneFailureLocalized("Clone failed"),
                    description: cloneFailureLocalized("The clone task is no longer available.")
                )
            }
        }
        .accessibilityIdentifier("gitok.clone.failure")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface)
    }

    private func detail(_ task: CloneTask) -> some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            AppCard(
                style: .subtle,
                cornerRadius: DesignTokens.Radius.md,
                showShadow: false
            ) {
                HStack(spacing: AppUI.Spacing.sm) {
                    Image(systemName: task.status == .cancelled
                        ? "xmark.circle.fill"
                        : "exclamationmark.triangle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(task.status == .cancelled ? theme.warning : theme.error)
                        .frame(width: 34, height: 34)
                        .background(
                            (task.status == .cancelled ? theme.warning : theme.error).opacity(0.12),
                            in: Circle()
                        )

                    VStack(alignment: .leading, spacing: AppUI.Spacing.xs) {
                        Text(task.status == .cancelled
                            ? cloneFailureLocalized("Clone cancelled")
                            : cloneFailureLocalized("Clone failed"))
                            .font(.appTitle)
                            .foregroundStyle(theme.textPrimary)
                        Text(project.title)
                            .font(.appCaption)
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer(minLength: AppUI.Spacing.sm)
                    AppTag(
                        task.status == .cancelled
                            ? cloneFailureLocalized("Clone cancelled")
                            : cloneFailureLocalized("Clone failed"),
                        systemImage: task.status == .cancelled
                            ? "xmark.circle.fill"
                            : "exclamationmark.triangle.fill"
                    )
                }
            }

            AppMetadataCard {
                if let detail = task.detail, !detail.isEmpty {
                    AppMetadataRow(title: cloneFailureLocalized("Current operation"), systemImage: "gearshape") {
                        Text(detail)
                            .font(.appBody)
                            .foregroundStyle(theme.textPrimary)
                    }
                    AppDivider()
                }

                AppMetadataRow(title: cloneFailureLocalized("Remote"), systemImage: "link") {
                    Text(task.remoteURL)
                        .font(.appMonoCaption)
                        .foregroundStyle(theme.textPrimary)
                        .textSelection(.enabled)
                }
                AppDivider()
                AppMetadataRow(title: cloneFailureLocalized("Destination"), systemImage: "folder") {
                    Text(task.destination.path)
                        .font(.appMonoCaption)
                        .foregroundStyle(theme.textPrimary)
                        .textSelection(.enabled)
                }
                if let startedAt = task.startedAt {
                    AppDivider()
                    AppMetadataRow(title: cloneFailureLocalized("Started"), systemImage: "play.circle") {
                        Text(startedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.appBody)
                            .foregroundStyle(theme.textPrimary)
                    }
                }
                AppDivider()
                AppMetadataRow(title: cloneFailureLocalized("Last update"), systemImage: "clock") {
                    Text(task.updatedAt.formatted(date: .abbreviated, time: .standard))
                        .font(.appBody)
                        .foregroundStyle(theme.textPrimary)
                }
            }

            if let error = task.errorMessage, !error.isEmpty {
                AppCard(
                    style: .subtle,
                    cornerRadius: DesignTokens.Radius.sm,
                    showShadow: false
                ) {
                    VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
                        Label(
                            cloneFailureLocalized("Clone failed"),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.appBodyEmphasized)
                        .foregroundStyle(theme.error)

                        Text(error)
                            .font(.appMonoCaption)
                            .foregroundStyle(theme.textPrimary)
                            .textSelection(.enabled)
                    }
                }
            }

            if let retryError {
                AppErrorBanner(message: LocalizedStringKey(retryError))
            }

            HStack(spacing: AppUI.Spacing.sm) {
                AppButton(
                    cloneFailureLocalized("Retry"),
                    systemImage: "arrow.clockwise",
                    style: .primary,
                    size: .small
                ) {
                    do {
                        _ = try cloneRepository.retry(taskID: task.id)
                        retryError = nil
                    } catch {
                        retryError = error.localizedDescription
                    }
                }
                .accessibilityIdentifier("gitok.clone.failure.retry")
                Spacer()
            }
        }
    }
}

@MainActor
private final class CloneFailureObservation: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CloneRepositoryObserverHandle)?

    init(cloneRepository: any CloneRepositoryProviding) {
        handle = cloneRepository.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
