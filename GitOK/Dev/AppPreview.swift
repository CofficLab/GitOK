import SwiftUI

struct AppPreview: View {
    var body: some View {
        Content()
            .modelContainer(AppConfig.getContainer())
            .environmentObject(AppManager())
            .environmentObject(WebConfig())
    }
}

#Preview {
    AppPreview()
}
