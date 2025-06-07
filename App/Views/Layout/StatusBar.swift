import MagicCore
import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarLeadingView()
            }
            Spacer()
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarTrailingView()
            }
        }
        .padding(.trailing, 10)
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .background(background)
    }
    
    private var background: some View {
        ZStack {
            if MagicApp.isDebug {
                MagicBackground.aurora.opacity(0.6)
            } else {
                MagicBackground.deepOceanCurrent.opacity(0.2)
            }
        }
    }
}

#Preview("StatusBar") {
    RootView {
        StatusBar()
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

