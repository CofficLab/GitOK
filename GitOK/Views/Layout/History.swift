import OSLog
import SwiftUI

struct History: View {
    @EnvironmentObject var app: AppManager

    var body: some View {
        if app.project != nil {
            VStack {
                Commits()
                Files()
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
