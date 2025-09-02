import SwiftUI
import MagicCore

struct BtnPush: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider
    
    @Binding var message: String

    @State var isPushing = false
    
    var path: String
    
    var body: some View {
        Button("推送", action: {
            do {
                try data.project?.push()
            } catch let error {
                
                m.warning("Push出错", subtitle: error.localizedDescription)
            }
        })
        .disabled(isPushing)
//        .onNotification(.gitPushStart, perform: { _ in
//            isPushing = true
//        })
//        .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
//            isPushing = false
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .gitPushFailed)) { _ in
//            isPushing = false
//        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
