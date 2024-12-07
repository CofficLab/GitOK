import SwiftData
import SwiftUI

struct RootView<Content>: View, SuperEvent where Content: View {
    var content: Content
    var m = MessageProvider()
    var a = AppProvider()
    var g = GitProvider()
    var b = BannerProvider()
    var i = IconProvider()
    @StateObject var p = PluginProvider()
    var c = AppConfig.getContainer()
    var w = WebConfig()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .modelContainer(c)
            .environmentObject(a)
            .environmentObject(g)
            .environmentObject(b)
            .environmentObject(i)
            .environmentObject(w)
            .environmentObject(p)
            .environmentObject(m)
            .onAppear(perform: onAppear)
            .onReceive(nc.publisher(for: .gitCommitStart), perform: onGitCommitStart)
            .onReceive(nc.publisher(for: .gitCommitSuccess), perform: onGitCommitSuccess)
            .onReceive(nc.publisher(for: .gitCommitFailed), perform: onGitCommitFailed)
            .onReceive(nc.publisher(for: .gitPushStart), perform: onGitPushStart)
            .onReceive(nc.publisher(for: .gitPushSuccess), perform: onGitPushSuccess)
            .onReceive(nc.publisher(for: .gitPushFailed), perform: onGitPushFailed)
            .onReceive(nc.publisher(for: .gitPullStart), perform: onGitPullStart)
            .onReceive(nc.publisher(for: .gitBranchChanged), perform: onGitBranchChanged)
    }
}

extension RootView {
    func onGitCommitStart(_ notification: Notification) {
        m.append("gitCommitStart")
    }

    func onGitPullStart(_ notification: Notification) {
        m.append("gitPullStart")
    }

    func onGitBranchChanged(_ notification: Notification) {
        m.append("gitBranchChanged to \(notification.userInfo?["branch"] ?? "")")
    }

    func onGitCommitSuccess(_ notification: Notification) {
        m.append("gitCommitSuccess")
    }

    func onGitCommitFailed(_ notification: Notification) {
        m.append("gitCommitFailed")
    }

    func onGitPushStart(_ notification: Notification) {
        m.append("gitPushStart")
    }

    func onGitPushSuccess(_ notification: Notification) {
        m.append("gitPushSuccess")
    }

    func onGitPushFailed(_ notification: Notification) {
        m.append("gitPushFailed")
    }

    func onAppear() {
        p.plugins.forEach { $0.onAppear() }
    }
}

#Preview("APP") {
    RootView(content: {
        Content()
    })
    .frame(width: 800, height: 800)
}
