import os
import SwiftUI
import MagicCore

struct IconAssetList: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: AppProvider

    @State var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)

    var iconsCount: Int = IconPng.getTotalCount()

    var body: some View {
        GeometryReader { geo in
            GroupBox {
                ScrollView {
                    VStack {
                        LazyVGrid(columns: gridItems, spacing: 10) {
                            ForEach(0 ..< iconsCount, id: \.self) { i in
                                IconItem(iconId: i)
                            }
                        }
                        .onAppear {
                            gridItems = getGridItems(geo)
                        }
                        .onChange(of: geo.size.width) {
                            gridItems = getGridItems(geo)
                        }
                    }
                }
            }
        }
    }

    func getGridItems(_ geo: GeometryProxy) -> [GridItem] {
        Array(repeating: .init(.flexible()), count: calculateColumns(geo.size.width))
    }

    func calculateColumns(_ width: CGFloat) -> Int {
        let columns = Int(width / 80)
        return columns
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
