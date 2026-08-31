import Foundation

enum GitOKPluginAboutContentBuilder {
    struct Content: Sendable {
        let features: [GitOKPluginAboutView.Feature]
        let steps: [String]
        let tips: [String]
    }

    static func make(
        icon: String,
        displayName: String,
        description: String,
        kind: GitOKPluginAboutContentKind,
        locale: Locale
    ) -> Content {
        func text(_ key: String) -> String {
            GitOKPluginAboutLocalization.string(key, locale: locale)
        }

        func format(_ key: String, _ arguments: CVarArg...) -> String {
            GitOKPluginAboutLocalization.format(key, locale: locale, arguments)
        }

        let secondary: (String, String)
        let tertiary: (String, String)
        let steps: [String]
        let tips: [String]

        switch kind {
        case .general:
            secondary = ("about.general.feature.integration.title", "about.general.feature.integration.description")
            tertiary = ("about.general.feature.configurable.title", "about.general.feature.configurable.description")
            steps = [
                format("about.general.step.enable", displayName),
                text("about.general.step.register"),
                text("about.general.step.use"),
            ]
            tips = [
                text("about.general.tip.toggle"),
                text("about.general.tip.settings"),
            ]
        case .gitTool:
            secondary = ("about.gitTool.feature.workflow.title", "about.gitTool.feature.workflow.description")
            tertiary = ("about.gitTool.feature.configurable.title", "about.gitTool.feature.configurable.description")
            steps = [
                format("about.gitTool.step.enable", displayName),
                text("about.gitTool.step.openProject"),
                text("about.gitTool.step.use"),
            ]
            tips = [
                text("about.gitTool.tip.toggle"),
                text("about.gitTool.tip.gitState"),
            ]
        case .openIn:
            secondary = ("about.openIn.feature.access.title", "about.openIn.feature.access.description")
            tertiary = ("about.openIn.feature.project.title", "about.openIn.feature.project.description")
            steps = [
                text("about.openIn.step.enable"),
                text("about.openIn.step.openProject"),
                text("about.openIn.step.launch"),
            ]
            tips = [
                text("about.openIn.tip.installed"),
                text("about.openIn.tip.path"),
            ]
        case .statusBar:
            secondary = ("about.statusBar.feature.display.title", "about.statusBar.feature.display.description")
            tertiary = ("about.statusBar.feature.context.title", "about.statusBar.feature.context.description")
            steps = [
                format("about.statusBar.step.enable", displayName),
                text("about.statusBar.step.selectProject"),
                text("about.statusBar.step.observe"),
            ]
            tips = [
                text("about.statusBar.tip.toggle"),
                text("about.statusBar.tip.visibility"),
            ]
        case .theme:
            secondary = ("about.theme.feature.palette.title", "about.theme.feature.palette.description")
            tertiary = ("about.theme.feature.appearance.title", "about.theme.feature.appearance.description")
            steps = [
                format("about.theme.step.enable", displayName),
                text("about.theme.step.select"),
                text("about.theme.step.apply"),
            ]
            tips = [
                text("about.theme.tip.combine"),
                text("about.theme.tip.alwaysOn"),
            ]
        }

        let secondaryDescription: String
        if kind == .general {
            secondaryDescription = format("about.general.feature.integration.description", displayName)
        } else {
            secondaryDescription = text(secondary.1)
        }

        return Content(
            features: [
                .init(icon: icon, title: displayName, description: description),
                .init(
                    icon: secondaryFeatureIcon(for: kind),
                    title: text(secondary.0),
                    description: secondaryDescription
                ),
                .init(icon: "gearshape", title: text(tertiary.0), description: text(tertiary.1)),
            ],
            steps: steps,
            tips: tips
        )
    }

    private static func secondaryFeatureIcon(for kind: GitOKPluginAboutContentKind) -> String {
        switch kind {
        case .general: "puzzlepiece.extension"
        case .gitTool: "arrow.triangle.branch"
        case .openIn: "arrow.up.right.square"
        case .statusBar: "menubar.rectangle"
        case .theme: "paintpalette"
        }
    }
}
