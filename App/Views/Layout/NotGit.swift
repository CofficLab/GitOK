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
                Text("not_git_project", bundle: .main)
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
