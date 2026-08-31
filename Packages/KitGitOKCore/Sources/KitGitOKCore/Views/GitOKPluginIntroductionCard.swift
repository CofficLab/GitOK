import SwiftUI

public struct GitOKPluginIntroductionCard: View {
    let title: String
    let description: String
    let footnote: String?

    public init(title: String, description: String, footnote: String? = nil) {
        self.title = title
        self.description = description
        self.footnote = footnote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
