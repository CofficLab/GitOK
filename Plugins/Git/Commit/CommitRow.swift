import SwiftUI

struct CommitRow: View {
    let commit: GitCommit
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack {
                    Text(commit.message)
                        .lineLimit(1)
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(height: 25)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)

            Divider()
        }
    }
}

#Preview {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}
