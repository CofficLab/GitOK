import LumiUI
import ProviderActivity
import SwiftUI

/// 活动状态 tile：有活动时显示 spinner + 描述（对齐旧版 ActivityStatusTile）。
public struct ActivityStatusTile: View {
    let activity: any ActivityProviding
    @StateObject private var observation: ActivityObservationModel

    public init(activity: any ActivityProviding) {
        self.activity = activity
        _observation = StateObject(wrappedValue: ActivityObservationModel(activity: activity))
    }

    public var body: some View {
        if let status = activity.currentActivity, !status.isEmpty {
            HStack(spacing: 5) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text(status)
                    .font(.appCaption)
                    .lineLimit(1)
            }
            .help("Current activity")
        }
    }
}

/// 活动观察模型：订阅 `ActivityProviding` 事件，转成 @Published revision。
@MainActor
final class ActivityObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ActivityObserverHandle)?

    init(activity: any ActivityProviding) {
        handle = activity.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
