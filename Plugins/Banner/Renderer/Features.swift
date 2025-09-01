import SwiftUI

struct Features: View {
    @Binding var features: [String]
    @State var hovering = false

    var body: some View {
        LazyHGrid(rows: [
            GridItem(.flexible(minimum: 260, maximum: 300)),
            GridItem(.flexible(minimum: 260, maximum: 300)),
        ], spacing: 50) {
            ForEach(Array($features.enumerated()), id: \.offset) { i, badge in
                Feature(title: badge)
                    .contextMenu(ContextMenu(menuItems: {
                        btnDel(i)
                        btnAdd
                    }))
            }
        }
        // 如果无背景，右键菜单会失效
        .background(.red.opacity(0.01))
        .clipShape(Rectangle())
        .contextMenu(menuItems: {
            btnAdd
        })
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
    }

    func btnDel(_ i: Int) -> some View {
        Button("删除", action: {
            features.remove(atOffsets: [i])
        })
    }

    var btnAdd: some View {
        Button(action: {
            features.append("新特性")
        }) {
            Label("增加新特性", systemImage: "plus")
        }
    }
}

#Preview("App") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 800)
}
