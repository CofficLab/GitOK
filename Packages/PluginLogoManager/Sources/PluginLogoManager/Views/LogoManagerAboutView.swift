import LumiUI
import SwiftUI

/// Logo 管理器插件关于视图。
///
/// 集中管理 GitOK 的品牌 Logo 贡献：插件可注册自己的 logo 项，
/// 管理器统一排序、去重并维护高亮状态。
struct LogoManagerAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "photo.stack.fill",
                accent: theme.primary,
                tagline: L("One place that owns every logo in GitOK."),
                chips: [L("Central registry"), L("Ordered"), L("Highlight-aware")],
                metrics: [
                    .init(value: "1", label: L("logo provider")),
                    .init(value: "N", label: L("logo items"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "square.stack.3d.up.fill", tint: theme.primary,
                          title: L("Central Registry"),
                          description: L("Every plugin registers its logo contribution in one place.")),
                    .init(icon: "arrow.up.and.down", tint: theme.info,
                          title: L("Deterministic Order"),
                          description: L("Items are sorted and de-duplicated so the result is always stable.")),
                    .init(icon: "highlighter", tint: theme.warning,
                          title: L("Highlight State"),
                          description: L("Plugins can mark a logo as highlighted for special moments."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register"), description: L("A plugin contributes its logo item with an order."), icon: "plus.square.on.square"),
                    .init(title: L("Merge"), description: L("The manager merges, de-duplicates, and sorts all items."), icon: "arrow.triangle.merge"),
                    .init(title: L("Render"), description: L("Views read the final list and draw the active logo."), icon: "photo.fill")
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
    ScrollView {
        LogoManagerAboutView()
            .padding(22)
    }
    .frame(width: 560, height: 900)
}
