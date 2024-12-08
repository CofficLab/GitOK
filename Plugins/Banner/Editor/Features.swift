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

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var previewBanner = BannerModel(
            title: "制作海报",
            subTitle: "简单又快捷",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: ""
        )

        var body: some View {
            RootView {
                BannerEditor(banner: $previewBanner)
            }
            .frame(width: 500)
            .frame(height: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 800)
}
