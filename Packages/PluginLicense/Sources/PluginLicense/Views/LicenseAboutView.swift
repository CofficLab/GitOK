import LumiUI
import SwiftUI

/// 许可证插件关于视图。
struct LicenseAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "checkmark.seal.fill",
                accent: theme.success,
                tagline: L("Licensing made transparent, for GitOK and your projects."),
                chips: [L("Open Source"), L("Attribution"), L("In-app")],
                metrics: [
                    .init(value: "100%", label: L("attribution")),
                    .init(value: "1", label: L("place to read"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "doc.text.fill", tint: theme.success,
                          title: L("Project License"),
                          description: L("Read GitOK's license and open-source notices in-app.")),
                    .init(icon: "person.2.fill", tint: theme.info,
                          title: L("Third-Party Credit"),
                          description: L("Every dependency is credited with its license terms.")),
                    .init(icon: "eye.fill", tint: theme.warning,
                          title: L("Transparency"),
                          description: L("Compliance information is one click away."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Open licenses"), description: L("Browse the license view from settings."), icon: "doc.text"),
                    .init(title: L("Read terms"), description: L("Each component's license text is available."), icon: "book"),
                    .init(title: L("Stay informed"), description: L("Updates keep attribution current."), icon: "arrow.clockwise")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        LicenseLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { LicenseAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
