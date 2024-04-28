import SwiftUI

struct NoChanges: View {
    @EnvironmentObject var app: AppManager

    var body: some View {
        VStack {
            Spacer()
            Text("本地无变动")
            Spacer()
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
