import SwiftData
import SwiftUI

struct RootView<Content>: View where Content: View {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(AppManager())
    }
}

#Preview("APP") {
    RootView(content: {
        Content()
    })
}
