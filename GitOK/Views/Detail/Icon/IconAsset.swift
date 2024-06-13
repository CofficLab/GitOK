import os
import SwiftUI

struct IconAsset: View {
    @Binding var iconId: Int

    @State var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)

    var iconsCount: Int = IconPng.getTotalCount()

    var body: some View {
        GeometryReader { geo in
            GroupBox {
                ScrollView {
                    VStack {
                        LazyVGrid(columns: gridItems, spacing: 10) {
                            ForEach(0 ..< iconsCount, id: \.self) { i in
                                IconItem(selected: i == iconId, iconId: i)
                                    .onTapGesture {
                                        iconId = i
                                    }
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

#Preview("App") {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
