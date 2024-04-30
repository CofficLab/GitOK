import SwiftData
import SwiftUI

struct IconHome: View {
    @EnvironmentObject var app: AppManager
    @Environment(\.modelContext) var context: ModelContext

    @Binding var icon: IconModel?
    @State var iconId = 1
    @State var snapshotTapped: Bool = false
    @State var backgroundId: String = "4"

    var body: some View {
        GeometryReader { geo in
            HStack {
                // MARK: 图标列表

                IconList(iconId: $iconId)
                    .frame(width: geo.size.width * 0.2)

                // MARK: 图标生成器

                if let icon = icon {
                    IconMaker(
                        snapshotTapped: $snapshotTapped,
                        iconId: icon.iconId,
                        backgroundId: icon.backgroundId
                    )
                    .tag(Optional(icon))
                    .tabItem { Text(icon.title) }
                    .onAppear {
                        self.iconId = icon.iconId
                    }
                    .frame(width: geo.size.width * 0.6)
                }

                if let icon = icon {
                    VStack {
                        Spacer()
                        IconFields(icon: icon)

                        GroupBox {
                            Backgrounds(current: $backgroundId)
                        }
                    }
                    .padding(.trailing, 10)
                    .frame(width: geo.size.width * 0.2)
                }
            }
        }
        .padding()
        .toolbar(content: {
            ToolbarItem(placement: .primaryAction, content: {
                Button("截图", action: {
                    self.snapshotTapped = true
                })
            })
        })
        .onAppear {
            self.iconId = icon?.iconId ?? 1
        }
        .onChange(of: iconId) {
            if let icon = icon {
                icon.iconId = iconId
            }
        }
        .onChange(of: backgroundId) {
            icon?.backgroundId = backgroundId
        }
    }
}

#Preview("IconHome") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
        .frame(maxWidth: .infinity)
}
