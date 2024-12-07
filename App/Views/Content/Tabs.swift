import SwiftUI

struct Tabs: View {
    @EnvironmentObject var p: PluginProvider

    @Binding var tab: ActionTab

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if self.tab == .Git {
                    CommitList()
                } else if self.tab == .Banner {
                    p.plugins.first { $0 is BannerPlugin }?.addListView()
                } else if self.tab == .Icon {
                    IconList()
                } else {
                    Spacer()
                }
            }.frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
