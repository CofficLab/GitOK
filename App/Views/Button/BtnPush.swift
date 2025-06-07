import SwiftUI

struct BtnPush: View {
    @EnvironmentObject var m: MessageProvider
    
    @Binding var message: String

    @State var isPushing = false
    
    var path: String
    
    var body: some View {
        Button("推送", action: {
            do {
                try GitShell.push(path)
            } catch let error {
                m.alert("Push出错", info: error.localizedDescription)
            }
        })
        .disabled(isPushing)
        .onReceive(NotificationCenter.default.publisher(for: .gitPushStart)) { _ in
            isPushing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
            isPushing = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPushFailed)) { _ in
            isPushing = false
        }
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
