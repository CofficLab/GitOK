import SwiftData
import SwiftUI

struct RootView<Content>: View where Content: View {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .modelContainer(AppConfig.getContainer())
            .environmentObject(AppProvider())
            .environmentObject(WebConfig())
            .environmentObject(PluginProvider())
            .environmentObject(MessageProvider())
    }
}

#Preview("APP") {
    RootView(content: {
        Content()
    })
    .frame(height: 800)
    .frame(width: 800)
}
