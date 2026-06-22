
import SwiftUI
import GitOKCoreKit

struct IconWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text(String(localized: "icon-workshop"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(String(localized: "在这里，您可以轻松为您的 macOS 和 iOS 应用创建精美的图标。"))
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Divider()
                .padding(.horizontal, 60)
                .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 15) {
                BtnNewIcon()
                    .frame(width: 250)
                    .frame(height: 40)
            }
            .font(.headline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
