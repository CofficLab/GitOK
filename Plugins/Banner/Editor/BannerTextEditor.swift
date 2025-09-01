import SwiftUI

struct BannerTextEditor: View {
    @State private var isEditing = false // 双击编辑状态
    @State private var isFormatting = false // 单击格式化状态
    @State private var hoveredColor: Color?

    private let colorOptions: [Color] = [
        .black, .white, .red, .green, .blue,
    ]

    @Binding var banner: BannerFile
    let isTitle: Bool // 用于区分是标题还是副标题

    var text: Binding<String> {
        isTitle ? $banner.title : $banner.subTitle
    }

    var color: Binding<Color?> {
        isTitle ? $banner.titleColor : $banner.subTitleColor
    }

    var placeholder: String {
        isTitle ? "标题" : "副标题"
    }

    var fontSize: CGFloat {
        isTitle ? 200 : 100
    }

    var body: some View {
        ZStack {
            // 背景点击层
            if isFormatting || isEditing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFormatting = false
                            isEditing = false
                        }
                    }
                    .ignoresSafeArea()
            }

            VStack {
                if isEditing {
                    // 编辑模式
                    TextField(placeholder, text: text)
                        .font(.system(size: fontSize))
                        .foregroundColor(color.wrappedValue ?? .white)
                        .tint(.white)
                        .background(.clear)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.yellow.opacity(0.6))
                        )
                        .onSubmit {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.isEditing = false
                            }
                        } // 编辑模式工具栏
                        .overlay(alignment: .top) {
                            HStack(spacing: 30) {
                                Button(action: { }) {
                                    Text("B")
                                        .font(.system(size: 24, weight: .bold))
                                }
                                Button(action: { }) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 24))
                                }
                                Button(action: { }) {
                                    Text("18")
                                        .font(.system(size: 24))
                                }
                                Button(action: { }) {
                                    Circle()
                                        .fill(.black)
                                        .frame(width: 24, height: 24)
                                }
                                Button(action: { }) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 24))
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.background)
                                    .shadow(color: .black.opacity(0.15), radius: 10)
                            )
                            .offset(y: -80)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                } else {
                    // 显示模式
                    Text(text.wrappedValue.isEmpty ? placeholder : text.wrappedValue)
                        .font(.system(size: fontSize))
                        .foregroundColor(color.wrappedValue ?? .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.white.opacity(0.6))
                                .opacity(isFormatting ? 1 : 0)
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        self.isEditing = true
                                        self.isFormatting = false
                                    }
                                }
                                .simultaneously(with: TapGesture(count: 1)
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isFormatting.toggle()
                                        }
                                    }
                                )
                        )
                        // 格式化工具栏
                        .overlay(alignment: .top) {
                            if isFormatting {
                                HStack(spacing: 20) {
                                    ForEach(colorOptions, id: \.self) { colorOption in
                                        Circle()
                                            .fill(colorOption)
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                                                    .opacity(hoveredColor == colorOption ? 1 : 0)
                                            )
                                            .onHover { isHovered in
                                                hoveredColor = isHovered ? colorOption : nil
                                            }
                                            .onTapGesture {
                                                color.wrappedValue = colorOption
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isFormatting = false
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.yellow.opacity(0.3))
                                        .shadow(color: .black.opacity(0.15), radius: 10)
                                )
                                .offset(y: -80)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                }
            }
        }
    }
}
