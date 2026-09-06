import LumiUI
import SwiftUI

/// 活动状态插件关于视图。
struct ActivityStatusAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "waveform.path.ecg.rectangle",
                accent: theme.success,
                tagline: L("GitOK's heartbeat, visible at a glance."),
                chips: [L("Running"), L("Idle"), L("Busy")],
                metrics: [
                    .init(value: "Live", label: L("state")),
                    .init(value: "1", label: L("tile"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "waveform.path.ecg", tint: theme.success,
                          title: L("Activity Feed"),
                          description: L("Repository events stream through a live indicator.")),
                    .init(icon: "gauge.with.dots.needle.50percent", tint: theme.info,
                          title: L("State Machine"),
                          description: L("Idle, running, and busy states reflect what GitOK is doing.")),
                    .init(icon: "square.grid.2x2", tint: theme.warning,
                          title: L("Tile Integration"),
                          description: L("The status renders as a compact tile in the workspace."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Events arrive"), description: L("Git operations and file events report activity."), icon: "waveform.path.ecg"),
                    .init(title: L("Update state"), description: L("The activity model transitions between states."), icon: "arrow.triangle.2.circlepath"),
                    .init(title: L("Render tile"), description: L("The tile redraws with the current heartbeat."), icon: "square.grid.2x2")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        ActivityStatusLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { ActivityStatusAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
