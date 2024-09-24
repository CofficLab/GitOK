import SwiftData
import SwiftUI

struct RootView<Content>: View where Content: View {
    private var content: Content
    var m = MessageProvider()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .modelContainer(AppConfig.getContainer())
            .environmentObject(AppProvider())
            .environmentObject(GitProvider())
            .environmentObject(WebConfig())
            .environmentObject(PluginProvider())
            .environmentObject(m)
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitStart)) { _ in
                m.append("gitCommitStart")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                m.append("gitCommitSuccess")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitFailed)) { _ in
                m.append("gitCommitFailed")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitPushStart)) { _ in
                m.append("gitPushStart")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
                m.append("gitPushSuccess")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitPushFailed)) { _ in
                m.append("gitPushFailed")
            }
    }
}

#Preview("APP") {
    RootView(content: {
        Content()
    })
    .frame(height: 800)
    .frame(width: 800)
}
