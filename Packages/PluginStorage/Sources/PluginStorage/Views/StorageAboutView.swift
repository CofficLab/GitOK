import LumiUI
import SwiftUI

/// 存储插件关于视图。
///
/// 为 GitOK 与所有插件提供统一的数据根目录：按应用支持目录
/// 创建版本隔离的存储空间，让每个插件拥有独立的数据目录。
struct StorageAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "externaldrive.fill",
                accent: theme.warning,
                tagline: L("One safe home for every plugin's data."),
                chips: [L("App Support"), L("Versioned"), L("Isolated")],
                metrics: [
                    .init(value: "1", label: L("data root")),
                    .init(value: "1", label: L("directory per plugin"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "externaldrive", tint: theme.warning,
                          title: L("Central Data Root"),
                          description: L("All plugin data lives under one Application Support directory.")),
                    .init(icon: "square.stack.3d.up.fill", tint: theme.primary,
                          title: L("Per-Plugin Isolation"),
                          description: L("Each plugin gets its own directory, so nothing leaks between features.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.info,
                          title: L("Version Aware"),
                          description: L("The storage path encodes the app major version, easing clean upgrades."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Resolve the root"), description: L("GitOK locates its Application Support folder."), icon: "folder"),
                    .init(title: L("Create the space"), description: L("A versioned data directory is created if needed."), icon: "externaldrive.fill"),
                    .init(title: L("Hand out directories"), description: L("Plugins request and receive their own subdirectories on demand."), icon: "square.stack.3d.up")
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
        StorageAboutView()
            .padding(22)
    }
    .frame(width: 560, height: 900)
}
