import MagicCore
import SwiftUI
import OSLog

struct IconBgs: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0 ..< MagicBackgroundGroup.all.count, id: \.self) { index in
                    let gradient = MagicBackgroundGroup.all[index]
                    makeItem(gradient)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 70)
    }

    func makeItem(_ gradient: MagicBackgroundGroup.GradientName) -> some View {
        Button(action: {
            if var icon = self.i.currentModel {
                do {
                    try icon.updateBackgroundId(gradient.rawValue)
                } catch {
                    m.error(error.localizedDescription)
                }
            } else {
                m.error("先选择一个图标文件")
            }
        }) {
            ZStack {
                MagicBackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if self.i.currentModel?.backgroundId == gradient.rawValue {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
