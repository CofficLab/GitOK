import SwiftUI

public struct GitOKPluginAboutView: View {
    public struct Feature: Sendable {
        public let icon: String
        public let title: String
        public let description: String

        public init(icon: String, title: String, description: String) {
            self.icon = icon
            self.title = title
            self.description = description
        }
    }

    private let icon: String
    private let displayName: String
    private let description: String
    private let kind: GitOKPluginAboutContentKind
    private let footnote: String?

    @Environment(\.locale) private var locale

    public init(
        icon: String,
        displayName: String,
        description: String,
        kind: GitOKPluginAboutContentKind,
        footnote: String? = nil
    ) {
        self.icon = icon
        self.displayName = displayName
        self.description = description
        self.kind = kind
        self.footnote = footnote
    }

    public var body: some View {
        let content = GitOKPluginAboutContentBuilder.make(
            icon: icon,
            displayName: displayName,
            description: description,
            kind: kind,
            locale: locale
        )

        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(content.features.enumerated()), id: \.offset) { _, feature in
                featureRow(feature)
            }

            if content.steps.isEmpty == false {
                howItWorksCard(steps: content.steps)
            }

            if content.tips.isEmpty == false {
                tipsCard(tips: content.tips)
            }

            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func localized(_ key: String) -> String {
        GitOKPluginAboutLocalization.string(key, locale: locale)
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold))

                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(cardBackground)
    }

    private func howItWorksCard(steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized("about.section.howItWorks"))
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.tint)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                            )

                        Text(step)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func tipsCard(tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized("about.section.tips"))
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tint)
                            .frame(width: 16)

                        Text(tip)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
    }
}
