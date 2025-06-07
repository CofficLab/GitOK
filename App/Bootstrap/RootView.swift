import AlertToast
import SwiftData
import SwiftUI
import MagicCore

struct RootView<Content>: View, SuperEvent where Content: View {
    var content: Content
    var a: AppProvider
    var b: BannerProvider
    var i: IconProvider
    var p: PluginProvider
    
    private var box: RootBox
    
    @StateObject var m = MessageProvider()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        
        self.box = RootBox.shared
        self.a = box.app
        self.b = box.banner
        self.i = box.icon
        self.p = box.pluginProvider
    }

    var body: some View {
        content
            .toast(isPresenting: $m.showToast, alert: {
                AlertToast(type: .systemImage("info.circle", .blue), title: m.toast)
            }, completion: {
                m.clearToast()
            })
            .toast(isPresenting: $m.showAlert, alert: {
                AlertToast(displayMode: .alert, type: .error(.red), title: m.alert)
            }, completion: {
                m.clearAlert()
            })
            .toast(isPresenting: $m.showDone, alert: {
                AlertToast(type: .complete(.green), title: m.doneMessage)
            }, completion: {
                m.clearDoneMessage()
            })
            .toast(isPresenting: $m.showError, duration: 0, tapToDismiss: true, alert: {
                AlertToast(displayMode: .hud, type: .error(.indigo), title: m.error?.localizedDescription)
            }, completion: {
                m.clearError()
            })
            .environmentObject(a)
            .environmentObject(b)
            .environmentObject(i)
            .environmentObject(p)
            .environmentObject(m)
            .environmentObject(self.box.git)
            .onAppear(perform: onAppear)
//            .onReceive(nc.publisher(for: .gitCommitStart), perform: onGitCommitStart)
//            .onReceive(nc.publisher(for: .gitCommitSuccess), perform: onGitCommitSuccess)
//            .onReceive(nc.publisher(for: .gitCommitFailed), perform: onGitCommitFailed)
//            .onReceive(nc.publisher(for: .gitPushStart), perform: onGitPushStart)
//            .onReceive(nc.publisher(for: .gitPushSuccess), perform: onGitPushSuccess)
//            .onReceive(nc.publisher(for: .gitPushFailed), perform: onGitPushFailed)
//            .onReceive(nc.publisher(for: .gitPullStart), perform: onGitPullStart)
//            .onReceive(nc.publisher(for: .gitBranchChanged), perform: onGitBranchChanged)
    }
}

extension RootView {
    func onGitCommitStart(_ notification: Notification) {
        m.append("gitCommitStart", channel: "🌳 git")
    }

    func onGitPullStart(_ notification: Notification) {
        m.append("gitPullStart", channel: "🌳 git")
    }

    func onGitBranchChanged(_ notification: Notification) {
        m.append("gitBranchChanged to \(notification.userInfo?["branch"] ?? "")", channel: "🌳 git")
    }

    func onGitCommitSuccess(_ notification: Notification) {
        m.append("gitCommitSuccess", channel: "🌳 git")
    }

    func onGitCommitFailed(_ notification: Notification) {
        m.append("gitCommitFailed", channel: "🌳 git")
    }

    func onGitPushStart(_ notification: Notification) {
        m.append("gitPushStart", channel: "🌳 git")
    }

    func onGitPushSuccess(_ notification: Notification) {
        m.append("gitPushSuccess", channel: "🌳 git")
    }

    func onGitPushFailed(_ notification: Notification) {
        m.append("gitPushFailed", channel: "🌳 git")
    }

    func onAppear() {
//        p.plugins.forEach { $0.onAppear() }
    }
}

struct AppPreview: View {
    var body: some View {
        RootView {
            ContentLayout()
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
    })
    .frame(width: 800, height: 800)
}

#Preview("Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

