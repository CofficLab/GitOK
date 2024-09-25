import SwiftUI
import UniformTypeIdentifiers
import MagicKit

struct ScreeniPad<Content>: View where Content: View {
    private let content: Content

    var horizon = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                fullView
//                VStack {
//                    Text(getDeviceSize())
//                        .foregroundStyle(.red)
//                        .font(.system(size: 100))
//                    Text(getScreenSize())
//                        .foregroundStyle(.red)
//                        .font(.system(size: 100))
//                }
            }
            .scaleEffect(getScale(geo), anchor: .topLeading)
            .offset(x: getOffsetX(geo), y: getOffsetY(geo))
        }
//        .background(.blue)
    }

    @MainActor var fullView: some View {
        ZStack {
            content
                .frame(width: screenWidth, height: screenHeight)
                .background(.blue.opacity(0.5))

            getDeviceImage()
        }
//        .background(.yellow)
        .frame(width: getDeviceWidth())
        .frame(height: getDeviceHeight())
    }

    private func getDeviceImage() -> Image {
        return
            Image(horizon ? "iPad mini - Starlight - Landscape" : "iPad mini - Starlight - Portrait")
    }

    // MARK: 设备图片的屏幕的宽度

    var screenWidth: CGFloat {
        horizon ? 2275 : 1488
    }

    // MARK: 设备图片的屏幕的高度

    var screenHeight: CGFloat {
        horizon ? 1500 : 2266
    }
    
    // MARK: X的偏移量，用于居中
    
    @MainActor func getOffsetX(_ geo: GeometryProxy) -> CGFloat {
        if getScale(geo) == geo.size.width/getDeviceWidth() {
            return 0
        }
        
        return (geo.size.width-getScale(geo)*getDeviceWidth())*0.5
    }
    
    // MARK: Y的偏移量，用于居中
    
    @MainActor func getOffsetY(_ geo: GeometryProxy) -> CGFloat {
        if getScale(geo) == geo.size.height/getDeviceHeight() {
            return 0
        }
        
        return (geo.size.width-getScale(geo)*getDeviceHeight())*0.5
    }
    
    // MARK: 缩放的比例
    
    @MainActor func getScale(_ geo: GeometryProxy) -> CGFloat {
        min(geo.size.width / getDeviceWidth(), geo.size.height / getDeviceHeight())
    }
    
    // MARK: 设备图片的高度

    @MainActor private func getDeviceHeight() -> CGFloat {
        CGFloat(ImageHelper.getViewHeigth(getDeviceImage()))
    }

    // MARK: 设备图片的宽度

    @MainActor private func getDeviceWidth() -> CGFloat {
        CGFloat(ImageHelper.getViewWidth(getDeviceImage()))
    }

    // MARK: 设备图片的尺寸

    @MainActor private func getDeviceSize() -> String {
        let deviceImage = getDeviceImage()
        return "\(ImageHelper.getViewWidth(deviceImage)) X \(ImageHelper.getViewHeigth(deviceImage))"
    }

    // MARK: 设备图片的屏幕尺寸

    @MainActor private func getScreenSize() -> String {
        "\(screenWidth) X \(screenHeight)"
    }
}

#Preview("1号") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("iPad") {
    ScreeniPad(content: {
        Color.blue
    })
}

#Preview("iPad") {
    ScreeniPad(content: {
        Color.red
    }).frame(width: 800, height: 700)
}
