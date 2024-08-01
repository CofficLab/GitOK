import SwiftUI

struct BtnPush: View {
    @EnvironmentObject var app: AppProvider
    
    @Binding var message: String
    
    var path: String
    
    var body: some View {
        Button("推送", action: {
            do {
                message = try Git.push(path)
            } catch let error {
                app.alert("Push出错", info: error.localizedDescription)
            }
        })
    }
}

#Preview {
    AppPreview()
}
