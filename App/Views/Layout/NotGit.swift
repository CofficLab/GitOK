import OSLog
import SwiftData
import SwiftUI

struct NotGit: View {
    @EnvironmentObject var app: AppProvider

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("不是Git项目")
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
