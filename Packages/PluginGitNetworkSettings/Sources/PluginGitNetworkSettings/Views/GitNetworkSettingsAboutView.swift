import LumiUI
import SwiftUI

/// Git 网络设置插件关于视图。
struct GitNetworkSettingsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "network",
                accent: theme.info,
                tagline: L("Talk to remotes the way your network expects."),
                chips: [L("Proxy"), L("SSL"), L("Timeouts")],
                metrics: [
                    .init(value: "3", label: L("tuning areas")),
                    .init(value: "1", label: L("global config"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "arrow.triangle.branch.network", tint: theme.info,
                          title: L("Proxy Support"),
                          description: L("Route Git traffic through HTTP or SOCKS proxies.")),
                    .init(icon: "lock.shield", tint: theme.warning,
                          title: L("SSL Verification"),
                          description: L("Tune certificate verification for corporate environments.")),
                    .init(icon: "timer", tint: theme.success,
                          title: L("Timeout Control"),
                          description: L("Set connection and operation timeouts to match your network."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Adjust settings"), description: L("Configure proxy, SSL, and timeout values."), icon: "slider.horizontal.3"),
                    .init(title: L("Persist"), description: L("Settings are written to the Git config."), icon: "gearshape"),
                    .init(title: L("Apply to remotes"), description: L("All network operations honor the new values."), icon: "network")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitNetworkSettingsLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitNetworkSettingsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
