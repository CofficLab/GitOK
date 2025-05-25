import SwiftUI

struct NoCommit: View {
    var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text(LocalizedStringKey("select_commit_title"))
                    .font(.headline)
                    .padding()

                Text(LocalizedStringKey("select_commit_description"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
