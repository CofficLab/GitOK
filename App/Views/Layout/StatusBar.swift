import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var p: PluginProvider
    
    var body: some View {
        HStack(spacing: 0) {
            p.getPlugins()
        }
        .padding(.trailing, 10)
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .background(BackgroundView.type2.opacity(0.2))
    }
}

#Preview("StatusBar") {
    RootView {
        StatusBar()
    }
}
