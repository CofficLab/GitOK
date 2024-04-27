import SwiftUI

struct NoChanges: View {
    @EnvironmentObject var app: AppManager

    var body: some View {
        Text("本地无变动")
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
