import SwiftUI

struct DBEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "database")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Database Selected")
                .font(.title2)

            Text("Select a database configuration from the list or add a new one.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
