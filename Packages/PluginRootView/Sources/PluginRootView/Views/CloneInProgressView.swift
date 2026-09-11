import LumiUI
import ProviderCloneRepository
import ProviderProjects
import SwiftUI

/// 当前项目正在后台克隆时由根工作区显示的状态视图。
@MainActor
struct CloneInProgressView: View {
    let project: Project
    let cloneRepository: any CloneRepositoryProviding

    @StateObject private var observation: CloneInProgressObservation
    @LumiTheme private var theme

    init(project: Project, cloneRepository: any CloneRepositoryProviding) {
        self.project = project
        self.cloneRepository = cloneRepository
        _observation = StateObject(
            wrappedValue: CloneInProgressObservation(cloneRepository: cloneRepository)
        )
    }

    private var task: CloneTask? {
        _ = observation.revision
        return cloneRepository.task(for: project.url)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(theme.primary)

            VStack(spacing: 8) {
                Text(LumiPluginLocalization.string("Cloning repository", bundle: .module))
                    .font(.appTitle)
                    .foregroundStyle(theme.textPrimary)

                Text(project.title)
                    .font(.appBody)
                    .foregroundStyle(theme.textSecondary)

                Text(LumiPluginLocalization.string(
                    "GitOK is cloning this repository in the background.",
                    bundle: .module
                ))
                .font(.callout)
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            }

            if let task {
                VStack(spacing: 8) {
                    if let fraction = task.fractionCompleted {
                        ProgressView(value: fraction)
                        Text("\(Int(fraction * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.textSecondary)
                    } else {
                        ProgressView()
                    }

                    if let detail = task.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: 360)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface)
        .onDisappear {
            observation.cancel()
        }
    }
}

@MainActor
private final class CloneInProgressObservation: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CloneRepositoryObserverHandle)?

    init(cloneRepository: any CloneRepositoryProviding) {
        handle = cloneRepository.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
    }
}
