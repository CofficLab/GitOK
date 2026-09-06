import LumiUI
import SwiftUI

/// Open In 插件家族的共享「关于」视图。
///
/// 11 个 `Open*` 插件共用同一套落地页：工具栏一键把当前项目文件夹交给外部
/// 应用（Remote 则是在浏览器中打开远程仓库）。每个插件通过 `OpenTarget`
/// 注入自己的图标与名称，文案全部走运行时本地化（默认英语）。
public struct OpenInAboutView: View {
    @LumiTheme private var theme

    private let target: OpenTarget

    public init(target: OpenTarget) {
        self.target = target
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            hero
            spotlight
            capabilitiesSection
            howItWorksSection
        }
    }

    // MARK: - Hero

    private var hero: some View {
        LandingHero(
            icon: target.systemImage,
            accent: theme.primary,
            tagline: isRemote
                ? L("Open the current project's remote repository in your browser.")
                : L("Open the current project folder in %@ directly from the toolbar.", target.displayName),
            chips: isRemote
                ? [L("Toolbar Button"), L("Remote"), L("Default Browser")]
                : [L("Toolbar Button"), L("Current Project"), target.displayName],
            metrics: [
                .init(value: "1", label: L("Click")),
                .init(value: L("Low"), label: L("Permission"))
            ]
        )
        .landingAppear()
    }

    // MARK: - Spotlight

    private var spotlight: some View {
        LandingSpotlight(
            icon: isRemote ? "safari" : "arrow.up.forward.app",
            tint: theme.primary,
            title: isRemote ? L("Your repository, one click away") : L("A direct handoff to %@", target.displayName),
            message: isRemote
                ? L("Keep working in GitOK while viewing the current repository's remote on the web.")
                : L("Keep your Git work in GitOK while handing the current project folder to %@.", target.displayName)
        ) {
            AppTag(target.displayName, style: .accent)
        }
        .landingAppear(delay: 0.05)
    }

    // MARK: - Core Capabilities

    private var capabilitiesSection: some View {
        LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
            LandingFeatureGrid(items: isRemote ? remoteFeatures : localFeatures, minColumnWidth: 180)
        }
        .landingAppear(delay: 0.1)
    }

    private var localFeatures: [LandingFeatureItem] {
        [
            .init(
                icon: "folder",
                tint: theme.primary,
                title: L("Current Project"),
                description: L("Opens the folder of the project you are currently working on.")
            ),
            .init(
                icon: "arrow.up.forward.app",
                tint: theme.info,
                title: L("External App"),
                description: L("Launches %@ with the folder as its target.", target.displayName)
            ),
            .init(
                icon: "lock.shield",
                tint: theme.success,
                title: L("Low Risk"),
                description: L("Only opens; it never modifies your repository.")
            )
        ]
    }

    private var remoteFeatures: [LandingFeatureItem] {
        [
            .init(
                icon: "link",
                tint: theme.primary,
                title: L("Remote URL"),
                description: L("Reads the origin remote of the current repository.")
            ),
            .init(
                icon: "safari",
                tint: theme.info,
                title: L("Default Browser"),
                description: L("Opens the remote page in your default browser.")
            ),
            .init(
                icon: "globe",
                tint: theme.success,
                title: L("Any Remote"),
                description: L("Works with GitHub, GitLab, Gitee, and other remotes.")
            )
        ]
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
            LandingStepFlow(steps: isRemote ? remoteSteps : localSteps)
        }
        .landingAppear(delay: 0.15)
    }

    private var localSteps: [LandingStep] {
        [
            .init(
                title: L("Click the Button"),
                description: L("Click the %@ button in the toolbar.", target.displayName),
                icon: "cursorarrow.click"
            ),
            .init(
                title: L("Resolve the App"),
                description: L("GitOK finds the installed %@ application.", target.displayName),
                icon: "magnifyingglass"
            ),
            .init(
                title: L("Open in %@", target.displayName),
                description: L("The project folder opens directly in %@.", target.displayName),
                icon: target.systemImage
            )
        ]
    }

    private var remoteSteps: [LandingStep] {
        [
            .init(
                title: L("Click the Button"),
                description: L("Click the Remote button in the toolbar."),
                icon: "cursorarrow.click"
            ),
            .init(
                title: L("Read the Remote"),
                description: L("GitOK reads the origin remote of the current repository."),
                icon: "link"
            ),
            .init(
                title: L("Open in Browser"),
                description: L("The remote page opens in your default browser."),
                icon: "safari"
            )
        ]
    }

    private var isRemote: Bool { target == .remote }

    // MARK: - Localization

    private func L(_ key: String) -> String {
        KitOpenInLocalization.string(key, bundle: .module)
    }

    private func L(_ format: String, _ arg: String) -> String {
        String(format: KitOpenInLocalization.string(format, bundle: .module), arg)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 22) {
            OpenInAboutView(target: .finder)
            OpenInAboutView(target: .remote)
        }
        .padding(22)
    }
    .frame(width: 560, height: 1200)
}
