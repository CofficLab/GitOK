import OSLog
import SwiftUI

struct SmartButton: View {
    @State private var hovered: Bool = false
    @State private var isButtonTapped = false
    @State private var showTips: Bool = false

    var title: String = "标题"
    var tips: String = ""
    var systemImage: String = "home"
    var resize = false
    var height: CGFloat = 30
    var selected = false
    var onTap: () -> Void = {
        os_log("点击了button")
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
            if resize == false {
                makeButton(geo)
            } else {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            makeButton(geo)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    func makeButton(_ geo: GeometryProxy? = nil) -> some View {
        Label(title: {
        Text(title)}, icon: {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        })
            .font(getSize(geo))
            .padding()
            .background(hovered || selected ? Color.gray.opacity(0.4) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
            .onHover(perform: { hovering in
                withAnimation(.easeInOut) {
                    hovered = hovering
                    showTips = tips.count > 0 && hovered
                }
            })
            .onTapGesture {
                withAnimation(.default) {
                    onTap()
                }
            }
    }

    func getSize(_ geo: GeometryProxy?) -> Font {
        if resize == false {
            return .body
        }

        guard let geo = geo else {
            return .system(size: 24)
        }

        return .system(size: min(geo.size.height, geo.size.width) * 0.45)
    }
}

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(7)
            .background(configuration.isPressed ? Color.gray.opacity(0.5) : .clear)
    }
}

#Preview("App") {
    AppPreview()
}
