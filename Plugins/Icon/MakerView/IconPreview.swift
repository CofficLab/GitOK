import MagicCore
import SwiftUI

struct IconPreview: View {
    let icon: IconModel
    let platform: String

    var body: some View {
        ZStack {
            // 背景
            icon.background
            
            // 图标
            icon.image
                .resizable()
                .scaledToFit()
        }
        .frame(width: 1024, height: 1024)
        .if(platform == "macOS") {
            $0.clipShape(RoundedRectangle(cornerSize: CGSize(
                width: 200,
                height: 200
            ))).padding(100)
        }
        // 将缩放应用到整个组合上，而不是单独的图标
        .if(icon.scale != nil) { view in
            view.scaleEffect(icon.scale ?? 1.0)
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
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
