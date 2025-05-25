import SwiftUI

struct NoCommit: View {
    @EnvironmentObject var g: GitProvider
    
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
                
                Text("当前项目：" + (g.project?.path ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("隐藏左侧栏") {
    RootView {
        ContentView()
            .hideSidebar()
    }
        .frame(height: 600)
        .frame(width: 600)
}
