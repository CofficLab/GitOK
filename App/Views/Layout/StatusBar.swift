import SwiftUI
import MagicKit

struct StatusBar: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var p: PluginProvider
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(p.plugins, id: \.label) { plugin in
                plugin.addToolBarLeadingView()
            }
            Spacer()
            ForEach(p.plugins, id: \.label) { plugin in
                plugin.addToolBarTrailingView()
            }
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
