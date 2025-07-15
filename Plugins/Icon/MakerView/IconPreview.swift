import MagicCore
import SwiftUI

struct IconPreview: View {
    let icon: IconModel
    let platform: String

    var body: some View {
        ZStack {
            icon.background

            HStack {
                if let scale = icon.scale {
                    icon.image.scaleEffect(scale)
                } else {
                    icon.image.resizable().scaledToFit()
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .if(platform == "macOS") {
            $0.clipShape(RoundedRectangle(cornerSize: CGSize(
                width: 200,
                height: 200
            ))).padding(100)
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
