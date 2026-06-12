import Foundation
import GitOKUI
import GitOKSupportKit
import Sparkle
import SwiftUI

/// 检查更新视图模型
public final class CheckForUpdatesViewModel: ObservableObject, SuperLog {
    nonisolated public static let emoji = "⬆️"
    nonisolated static let verbose = false

    @Published public var canCheckForUpdates = false
    @Published public var automaticallyChecksForUpdates = false
    @Published public var feedURL: URL?

    public init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$automaticallyChecksForUpdates)
        updater.publisher(for: \.feedURL)
            .assign(to: &$feedURL)
    }
}

/// Sparkle 检查更新按钮
public struct UpdaterView: View, SuperLog {
    nonisolated public static let emoji = "⬆️"
    nonisolated static let verbose = false

    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    @State private var isChecking = false

    public init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    public var body: some View {
        AppButton(
            isChecking ? "正在检查更新..." : "检查更新",
            systemImage: "arrow.down.circle",
            style: .secondary,
            size: .small,
            isLoading: isChecking
        ) {
            isChecking = true
            updater.checkForUpdates()

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                isChecking = false
            }
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates || isChecking)
    }
}
