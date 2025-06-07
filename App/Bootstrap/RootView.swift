import AlertToast
import MagicCore
import SwiftData
import SwiftUI

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
            .navigationTitle("")
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
