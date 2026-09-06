import LumiUI
import SwiftUI

/// 诊断设置插件关于视图。
struct DiagnosticsSettingsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "stethoscope",
                accent: theme.warning,
                tagline: L("When something feels off, start here."),
                chips: [L("Logs"), L("Inspector"), L("Repro")],
                metrics: [
                    .init(value: "1", label: L("place to diagnose")),
                    .init(value: "Full", label: L("visibility"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "doc.text.magnifyingglass", tint: theme.warning,
                          title: L("Log Viewer"),
                          description: L("Browse GitOK's runtime logs with filters.")),
                    .init(icon: "gearshape.2", tint: theme.info,
                          title: L("Diagnostics Inspector"),
                          description: L("Inspect providers, plugins, and services state.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.success,
                          title: L("Repro Guidance"),
                          description: L("Export details that make issues reproducible."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Open diagnostics"), description: L("The diagnostics view loads current state."), icon: "stethoscope"),
                    .init(title: L("Inspect"), description: L("Logs and services are explored with filters."), icon: "doc.text.magnifyingglass"),
                    .init(title: L("Report"), description: L("Relevant details are exported for support."), icon: "square.and.arrow.up")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        LumiPluginLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { DiagnosticsSettingsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
