import SwiftData
import SwiftUI

struct IconHome: View {
    @EnvironmentObject var m: MessageProvider
    @Environment(\.modelContext) var context: ModelContext

    @Binding var icon: IconModel
    @State var iconId = 1
    @State var snapshotTapped: Bool = false
    @State var backgroundId: String = "4"

    var body: some View {
        VStack {
            // MARK: IconTopBar

            IconTopBar(snapshotTapped: $snapshotTapped, icon: $icon)
            GeometryReader { geo in
                HStack {
                    // MARK: Icon List

                    IconAsset(iconId: $iconId)
                        .frame(width: geo.size.width * 0.2)

                    // MARK: Preview

                    IconMaker(
                        snapshotTapped: $snapshotTapped,
                        icon: $icon
                    )
                    .tag(Optional(icon))
                    .tabItem { Text(icon.title) }
                    .onAppear {
                        self.iconId = icon.iconId
                    }
                }
            }
            .padding()
            .onAppear {
                self.iconId = icon.iconId
            }
            .onChange(of: iconId) {
                do {
                    try icon.updateIconId(iconId)
                } catch {
                    m.setError(error)
                }
            }
            .onChange(of: backgroundId) {
                do {
                    try icon.updateBackgroundId(backgroundId)
                } catch {
                    m.setError(error)
                }
            }
        }
    }
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
        .frame(maxWidth: .infinity)
}
