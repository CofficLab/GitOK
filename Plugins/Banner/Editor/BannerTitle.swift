import SwiftUI

struct BannerTitle: View {
    @State var isEditingTitle = false
    @State private var isShowingColorPicker = false

    // 预定义的颜色选项
    private let colorOptions: [Color] = [
        .red, .green, .yellow,
        .white, .black, .blue,
    ]

    @Binding var banner: BannerModel

    var body: some View {
        if isEditingTitle {
            GeometryReader { geo in
                TextField("", text: $banner.title)
                    .font(.system(size: 200))
                    .padding(.horizontal)
                    .frame(width: geo.size.width)
                    .onSubmit {
                        self.isEditingTitle = false
                    }
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 20) {
                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 2)
                            .onTapGesture {
                                banner.titleColor = color
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.background)
                        .shadow(radius: 3)
                )
                .offset(y: -50)
                .opacity(isShowingColorPicker ? 1 : 0)
                .animation(.easeInOut, value: isShowingColorPicker)

                Text(banner.title)
                    .font(.system(size: 200))
                    .foregroundColor(banner.titleColor ?? .white)
                    .onTapGesture {
                        self.isEditingTitle = true
                    }
            }
            .onHover { isHovering in
                isShowingColorPicker = isHovering
            }
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
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
