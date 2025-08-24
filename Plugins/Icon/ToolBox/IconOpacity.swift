import SwiftUI
import MagicCore

struct IconOpacity: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: AppProvider
    
    @State var icon: IconData?
    @State var opacity: Double = 1
    
    var body: some View {
        VStack {
            if icon != nil {
                Slider(value: $opacity, in: 0.1 ... 1)
                    .padding()
            }
        }
        .padding()
        .onAppear(perform: reloadData)
        .onChange(of: opacity, updateOpacity)
        .onChange(of: self.i.currentData) { _, newValue in
            reloadData()
        }
    }

    private func reloadData() {
        self.icon = i.currentData
        self.opacity = self.icon?.opacity ?? 1.0
    }

    private func updateOpacity() {
        if var icon = self.i.currentData {
            try? icon.updateOpacity(opacity)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
