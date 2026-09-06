import LumiUI
import SwiftUI

/// 状态栏插件关于视图。
struct StatusBarAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "rectangle.bottomthird.inset.filled",
                accent: theme.info,
                tagline: L("The quiet strip that keeps you oriented."),
                chips: [L("Status"), L("Hosts"), L("Extensible")],
                metrics: [
                    .init(value: "1", label: L("strip")),
                    .init(value: "N", label: L("indicators"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "rectangle.bottomthird.inset", tint: theme.info,
                          title: L("Central Strip"),
                          description: L("A shared status bar at the bottom of the workspace.")),
                    .init(icon: "square.stack.3d.up", tint: theme.primary,
                          title: L("Indicator Host"),
                          description: L("Plugins register indicators that appear in order.")),
                    .init(icon: "slider.horizontal.3", tint: theme.warning,
                          title: L("Order Control"),
                          description: L("Each indicator's position is deterministic."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register"), description: L("Plugins add their indicators with an order."), icon: "plus.square.on.square"),
                    .init(title: L("Compose"), description: L("The bar lays out all indicators."), icon: "rectangle.bottomthird.inset"),
                    .init(title: L("Update"), description: L("Indicators redraw as state changes."), icon: "arrow.clockwise")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        StatusBarLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { StatusBarAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
