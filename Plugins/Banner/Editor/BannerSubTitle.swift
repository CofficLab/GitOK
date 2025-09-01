import SwiftUI

struct BannerSubTitle: View {
    @State var isEditing = false
    @State private var isShowingColorPicker = false
    
    // 预定义的颜色选项
    private let colorOptions: [Color] = [
        .red, .green, .yellow,
        .white, .black, .blue,
    ]
    
    @Binding var banner: BannerData
    
    var body: some View {
        if isEditing {
            GeometryReader { geo in
                TextField("副标题", text: $banner.subTitle)
                    .font(.system(size: 100))
                    .padding(.horizontal)
                    .frame(width: geo.size.width)
                    .onSubmit {
                        self.isEditing = false
                    }
            }
        } else {
            Text(banner.subTitle.isEmpty ? "副标题" : banner.subTitle)
                .font(.system(size: 100))
                .foregroundColor(banner.subTitleColor ?? .white)
                .onTapGesture {
                    self.isEditing = true
                }
                .overlay(alignment: .top) {
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
                                    banner.subTitleColor = color
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
                    .offset(y: -150)
                    .opacity(isShowingColorPicker ? 1 : 0)
                    .animation(.easeInOut, value: isShowingColorPicker)
                    .onHover { isHovering in
                        isShowingColorPicker = isHovering
                    }
                }
        }
    }
}

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var previewBanner = BannerData(
            title: "制作海报",
            subTitle: "简单又快捷",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: "",
            project: Project.null
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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
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
