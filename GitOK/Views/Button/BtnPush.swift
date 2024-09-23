import SwiftUI

struct BtnPush: View {
    @EnvironmentObject var app: AppProvider
    
    @Binding var message: String

    @State var isPushing = false
    
    var path: String
    var git = Git()
    
    var body: some View {
        Button("推送", action: {
            do {
                message = try git.push(path)
            } catch let error {
                app.alert("Push出错", info: error.localizedDescription)
            }
        })
        .disabled(isPushing)
        .onReceive(NotificationCenter.default.publisher(for: .gitPushing)) { _ in
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

#Preview {
    AppPreview()
}
