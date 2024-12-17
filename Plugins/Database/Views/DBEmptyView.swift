import SwiftUI

struct DBEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "database")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("no_database_selected")
                .font(.title2)

            Text("no_database_description")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
